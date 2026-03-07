#!/usr/bin/env bash
# Claude Tokens Plugin — status line script
# Shows plan usage limits (session/weekly) + context window
# Fetches from api.anthropic.com/api/oauth/usage (zero LLM tokens)
# Caches results for 30 seconds

set -euo pipefail

CACHE_DIR="${HOME}/.claude/plugins/claude-tokens-plugin-cache"
CACHE_FILE="${CACHE_DIR}/usage-cache.json"
CACHE_TTL=30  # seconds

mkdir -p "$CACHE_DIR"

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
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || return 1

  if [[ -z "$response" ]] || echo "$response" | jq -e '.error' &>/dev/null; then
    return 1
  fi

  echo "$response" > "$CACHE_FILE"
}

# Check cache freshness
usage_data=""
if [[ -f "$CACHE_FILE" ]]; then
  cache_age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
  if [[ "$cache_age" -lt "$CACHE_TTL" ]]; then
    usage_data=$(cat "$CACHE_FILE")
  fi
fi

# Fetch fresh data if cache is stale
if [[ -z "$usage_data" ]]; then
  fetch_usage 2>/dev/null && usage_data=$(cat "$CACHE_FILE" 2>/dev/null) || true
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

parts=()

# Plan usage (5-hour session)
if [[ -n "$usage_data" ]]; then
  session_pct=$(echo "$usage_data" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
  weekly_pct=$(echo "$usage_data" | jq -r '.seven_day.utilization // empty' 2>/dev/null)

  if [[ -n "$session_pct" ]]; then
    session_int=$(printf '%.0f' "$session_pct")
    clr=$(color_for_pct "$session_int")
    parts+=("${clr}session ${session_int}%%${RESET}")
  fi

  if [[ -n "$weekly_pct" ]]; then
    weekly_int=$(printf '%.0f' "$weekly_pct")
    clr=$(color_for_pct "$weekly_int")
    parts+=("${clr}weekly ${weekly_int}%%${RESET}")
  fi
fi

# Context window
ctx_clr=$(color_for_pct "$CTX_PCT_INT")
parts+=("${ctx_clr}ctx ${CTX_PCT_INT}%%${RESET}")

# Join with separator
output=""
for i in "${!parts[@]}"; do
  if [[ $i -gt 0 ]]; then
    output+=" ${DIM}|${RESET} "
  fi
  output+="${parts[$i]}"
done

printf "$output"
