#!/usr/bin/env bash
# Claude Tokens Plugin — status line script
# Shows plan usage limits (session/weekly) + context window
# Fetches from api.anthropic.com/api/oauth/usage (zero LLM tokens)
# Caches results for 30 seconds

set -euo pipefail

CACHE_DIR="${HOME}/.claude/plugins/claude-tokens-plugin-cache"
CACHE_FILE="${CACHE_DIR}/usage-cache.json"
BACKOFF_FILE="${CACHE_DIR}/backoff.timestamp"
CONFIG_FILE="${CACHE_DIR}/config.json"
CACHE_TTL=60     # seconds between successful fetches
BACKOFF_TTL=120   # seconds to wait after rate limit

mkdir -p "$CACHE_DIR"

# --- Load locale config ---
LANG_SESSION="session"
LANG_WEEKLY="weekly"
LANG_CTX="ctx"
LANG_H="h"
LANG_M="m"
LANG_RATE_LIMIT="rate limit"
LANG_NO_UPDATES="no updates"
BASE_URL="https://api.anthropic.com"

if [[ -f "$CONFIG_FILE" ]]; then
  locale=$(jq -r '.locale // "en"' "$CONFIG_FILE" 2>/dev/null)
  base_url_override=$(jq -r '.base_url // empty' "$CONFIG_FILE" 2>/dev/null)
  if [[ -n "$base_url_override" ]]; then
    BASE_URL="$base_url_override"
  fi
  if [[ "$locale" == "ru" ]]; then
    LANG_SESSION="сессия"
    LANG_WEEKLY="неделя"
    LANG_CTX="контекст"
    LANG_H="ч"
    LANG_M="м"
    LANG_RATE_LIMIT="рейт лимит"
    LANG_NO_UPDATES="нет обновлений"
  fi
fi

# --- Read stdin (context window data from Claude Code) ---
INPUT=$(cat)
CTX_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' 2>/dev/null)
CTX_PCT_INT=$(printf '%.0f' "$CTX_PCT")
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // .model.id // "?"' 2>/dev/null)

# --- Fetch plan usage (with cache) ---
fetch_usage() {
  # Try macOS Keychain first
  local creds_json=""
  if [[ "$OSTYPE" == darwin* ]]; then
    creds_json=$(/usr/bin/security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)
  fi

  # Fallback to credentials file
  if [[ -z "$creds_json" ]]; then
    local cred_file="${HOME}/.claude/.credentials.json"
    if [[ -f "$cred_file" ]]; then
      creds_json=$(cat "$cred_file")
    fi
  fi

  if [[ -z "$creds_json" ]]; then
    return 1
  fi

  # Extract access token (handle nested claudeAiOauth structure)
  local token
  token=$(echo "$creds_json" | jq -r '.claudeAiOauth.accessToken // .accessToken // empty' 2>/dev/null)

  if [[ -z "$token" ]]; then
    return 1
  fi

  # Fetch usage from Anthropic API
  local response
  response=$(curl -s --max-time 5 \
    -H "Authorization: Bearer ${token}" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Content-Type: application/json" \
    "${BASE_URL}/api/oauth/usage" 2>/dev/null) || return 1

  if [[ -z "$response" ]]; then
    return 1
  fi
  if echo "$response" | jq -e '.error' &>/dev/null; then
    # Rate limited — записываем backoff timestamp, не пробуем снова N секунд
    date +%s > "$BACKOFF_FILE"
    return 1
  fi

  echo "$response" > "$CACHE_FILE"
}

# Check cache freshness
usage_data=""
stale_data=""
if [[ -f "$CACHE_FILE" ]]; then
  stale_data=$(cat "$CACHE_FILE")
  if [[ "$OSTYPE" == darwin* ]]; then
    cache_mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  else
    cache_mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
  fi
  cache_age=$(( $(date +%s) - cache_mtime ))
  if [[ "$cache_age" -lt "$CACHE_TTL" ]]; then
    usage_data="$stale_data"
  fi
fi

# Fetch fresh data if cache is stale
in_backoff=false
if [[ -f "$BACKOFF_FILE" ]]; then
  backoff_time=$(cat "$BACKOFF_FILE" 2>/dev/null || echo 0)
  backoff_age=$(( $(date +%s) - backoff_time ))
  [[ "$backoff_age" -lt "$BACKOFF_TTL" ]] && in_backoff=true
fi
if [[ -z "$usage_data" ]]; then
  if [[ "$in_backoff" == false ]] && fetch_usage 2>/dev/null; then
    usage_data=$(cat "$CACHE_FILE" 2>/dev/null)
  else
    # Use stale cache as fallback (better than nothing)
    usage_data="$stale_data"
  fi
fi

# --- Format output ---
RESET="\033[0m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"

color_for_pct() {
  local pct=$1
  if [[ "$pct" -ge 80 ]]; then
    echo "$RED"
  elif [[ "$pct" -ge 50 ]]; then
    echo "$YELLOW"
  else
    echo "$GREEN"
  fi
}

make_bar() {
  local pct=$1
  local clr=$2
  [[ $pct -gt 100 ]] && pct=100
  local width=20
  local filled=$(( pct * width / 100 ))
  local bar="${clr}"
  for ((i=0; i<filled; i++)); do bar+="━"; done
  bar+="${DIM}"
  for ((i=filled; i<width; i++)); do bar+="─"; done
  bar+="${RESET}"
  echo "$bar"
}

parts=()

# Rate limit backoff indicator
if [[ "$in_backoff" == true ]]; then
  parts+=("${YELLOW}${LANG_RATE_LIMIT}${RESET} ${DIM}(${LANG_NO_UPDATES})${RESET}")
fi

# Model name
if [[ -n "$MODEL" && "$MODEL" != "?" ]]; then
  parts+=("${MODEL}")
fi

# Plan usage (5-hour session)
if [[ -n "$usage_data" ]]; then
  session_pct=$(echo "$usage_data" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
  weekly_pct=$(echo "$usage_data" | jq -r '.seven_day.utilization // empty' 2>/dev/null)

  if [[ -n "$session_pct" ]]; then
    session_int=$(printf '%.0f' "$session_pct")
    clr=$(color_for_pct "$session_int")
    session_reset=""
    resets_at=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
    remaining_mins=""
    if [[ -n "$resets_at" ]]; then
      reset_epoch=$(date -d "$resets_at" +%s 2>/dev/null \
        || TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "${resets_at%%.*}" +%s 2>/dev/null \
        || true)
      if [[ -n "$reset_epoch" ]]; then
        remaining_mins=$(( (reset_epoch - $(date +%s)) / 60 ))
      fi
    fi
    if [[ -n "$remaining_mins" && "$remaining_mins" -gt 0 ]]; then
      r_h=$(( remaining_mins / 60 ))
      r_m=$(( remaining_mins % 60 ))
      if [[ $r_h -gt 0 ]]; then
        session_reset=" ${DIM}${r_h}${LANG_H} ${r_m}${LANG_M}${RESET}"
      else
        session_reset=" ${DIM}${r_m}${LANG_M}${RESET}"
      fi
    fi
    bar=$(make_bar "$session_int" "$clr")
    parts+=("${LANG_SESSION} ${bar} ${clr}${session_int}%%${RESET}${session_reset}")
  fi

  if [[ -n "$weekly_pct" ]]; then
    weekly_int=$(printf '%.0f' "$weekly_pct")
    clr=$(color_for_pct "$weekly_int")
    weekly_reset=""
    weekly_resets_at=$(echo "$usage_data" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)
    if [[ -n "$weekly_resets_at" ]]; then
      weekly_reset_epoch=$(date -d "$weekly_resets_at" +%s 2>/dev/null \
        || TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "${weekly_resets_at%%.*}" +%s 2>/dev/null \
        || true)
      if [[ -n "$weekly_reset_epoch" ]]; then
        weekly_remaining_mins=$(( (weekly_reset_epoch - $(date +%s)) / 60 ))
        if [[ "$weekly_remaining_mins" -gt 0 ]]; then
          r_h=$(( weekly_remaining_mins / 60 ))
          r_m=$(( weekly_remaining_mins % 60 ))
          r_d=$(( r_h / 24 ))
          r_h=$(( r_h % 24 ))
          if [[ $r_d -gt 0 ]]; then
            weekly_reset=" ${DIM}${r_d}d ${r_h}${LANG_H}${RESET}"
          elif [[ $r_h -gt 0 ]]; then
            weekly_reset=" ${DIM}${r_h}${LANG_H} ${r_m}${LANG_M}${RESET}"
          else
            weekly_reset=" ${DIM}${r_m}${LANG_M}${RESET}"
          fi
        fi
      fi
    fi
    bar=$(make_bar "$weekly_int" "$clr")
    parts+=("${LANG_WEEKLY} ${bar} ${clr}${weekly_int}%%${RESET}${weekly_reset}")
  fi
fi

# Context window
ctx_clr=$(color_for_pct "$CTX_PCT_INT")
ctx_bar=$(make_bar "$CTX_PCT_INT" "$ctx_clr")
parts+=("${LANG_CTX} ${ctx_bar} ${ctx_clr}${CTX_PCT_INT}%%${RESET}")

# Join with separator
output=""
for i in "${!parts[@]}"; do
  if [[ $i -gt 0 ]]; then
    output+=" ${DIM}|${RESET} "
  fi
  output+="${parts[$i]}"
done

printf "$output"
