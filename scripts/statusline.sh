#!/usr/bin/env bash
# Claude Tokens Plugin — status line script
# Reads JSON from stdin, outputs context window usage with color coding
# Zero LLM calls — pure bash + jq

set -euo pipefail

INPUT=$(cat)

# Context window
USED_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
CTX_SIZE=$(echo "$INPUT" | jq -r '.context_window.context_window_size // 0')
INPUT_TOKENS=$(echo "$INPUT" | jq -r '.context_window.current_usage.input_tokens // 0')
CACHE_CREATE=$(echo "$INPUT" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
CACHE_READ=$(echo "$INPUT" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

# Model
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // .model.id // "?"')

# Calculate total tokens
TOTAL_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))

# Format tokens (e.g. 125000 -> 125k)
if [ "$TOTAL_TOKENS" -ge 1000000 ] 2>/dev/null; then
  TOKENS_FMT=$(echo "$TOTAL_TOKENS" | awk '{printf "%.1fM", $1/1000000}')
elif [ "$TOTAL_TOKENS" -ge 1000 ] 2>/dev/null; then
  TOKENS_FMT=$(echo "$TOTAL_TOKENS" | awk '{printf "%.0fk", $1/1000}')
else
  TOKENS_FMT="${TOTAL_TOKENS}"
fi

# Round percentage to integer
PCT_INT=$(printf '%.0f' "$USED_PCT")

# Color based on context usage percentage
# ANSI: green=32, yellow=33, red=31
if [ "$PCT_INT" -ge 80 ] 2>/dev/null; then
  COLOR="\033[31m"  # red
elif [ "$PCT_INT" -ge 50 ] 2>/dev/null; then
  COLOR="\033[33m"  # yellow
else
  COLOR="\033[32m"  # green
fi
RESET="\033[0m"

printf "${COLOR}ctx ${PCT_INT}%%${RESET} ${TOKENS_FMT} | ${MODEL}"
