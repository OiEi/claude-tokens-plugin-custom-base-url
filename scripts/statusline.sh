#!/usr/bin/env bash
# Claude Tokens Plugin — status line script
# Reads JSON from stdin, outputs token usage with color coding
# Zero LLM calls — pure bash + jq

set -euo pipefail

INPUT=$(cat)

USED_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
TOTAL_TOKENS=$(echo "$INPUT" | jq -r '.context_window.total_input_tokens // 0')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "unknown"')

# Format cost to 2 decimal places
COST_FMT=$(printf '%.2f' "$COST")

# Format tokens (e.g. 125000 -> 125k)
if [ "$TOTAL_TOKENS" -ge 1000000 ] 2>/dev/null; then
  TOKENS_FMT="$(echo "$TOTAL_TOKENS" | awk '{printf "%.1fM", $1/1000000}')t"
elif [ "$TOTAL_TOKENS" -ge 1000 ] 2>/dev/null; then
  TOKENS_FMT="$(echo "$TOTAL_TOKENS" | awk '{printf "%.0fk", $1/1000}')t"
else
  TOKENS_FMT="${TOTAL_TOKENS}t"
fi

# Round percentage to integer
PCT_INT=$(printf '%.0f' "$USED_PCT")

# Color based on usage percentage
# ANSI: green=32, yellow=33, red=31
if [ "$PCT_INT" -ge 80 ] 2>/dev/null; then
  COLOR="\033[31m"  # red
elif [ "$PCT_INT" -ge 50 ] 2>/dev/null; then
  COLOR="\033[33m"  # yellow
else
  COLOR="\033[32m"  # green
fi
RESET="\033[0m"

printf "${COLOR}${PCT_INT}%% ${TOKENS_FMT}${RESET} | \$${COST_FMT} | ${MODEL}"
