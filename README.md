# claude-tokens-plugin

Lightweight Claude Code plugin that displays plan usage limits and context window in the status line. Zero LLM token consumption — fetches data from Anthropic API via pure bash + jq + curl.

## Display

```
claude-sonnet-4-6 | session ━━━━━━━─────────────── 37% 1h 45m | weekly ━━━━──────────────── 21% 6d 5h | ctx ━━────────────────── 10%
```

With Russian locale:
```
claude-sonnet-4-6 | сессия ━━━━━━━─────────────── 37% 1ч 45м | неделя ━━━━──────────────── 21% 6д 5ч | контекст ━━────────────────── 10%
```

Color-coded:
- **Green**: < 50%
- **Yellow**: 50–80%
- **Red**: > 80%

## Features

- **Progress bars** — colour-coded `━━━━━━━───────────────` bars (classic line style) for session, weekly, and context window
- **Active model** — current model name shown at the start of the status line
- **Reset countdowns** — time remaining until session resets (e.g. `1h 45m`) and weekly limit resets (e.g. `6d 5h`)
- **Rate limit resilience** — backoff mechanism prevents request storms when API rate limits; stale cache is always used as fallback
- **Locale support** — English and Russian

## Installation

```
/plugin marketplace add jointime1/claude-tokens-plugin
/plugin install claude-tokens-plugin
```

## Setup

Run the setup command to configure the status line:

```
/setup
```

It will ask your preferred language (English/Russian), configure `~/.claude/settings.json`, and you're done. Restart Claude Code to see the status line.

## Requirements

- [jq](https://jqlang.github.io/jq/)
- [curl](https://curl.se/)
- Claude Pro/Max subscription (OAuth credentials for usage API)

## How it works

The status line script:
1. Reads context window data and model info from stdin (provided by Claude Code)
2. Fetches plan usage (session/weekly limits) from `api.anthropic.com/api/oauth/usage` using your OAuth token
3. Caches API responses for 60 seconds; on rate limit error waits 2 minutes before retrying
4. Outputs a colour-coded summary line with progress bars and reset countdowns

No LLM calls are made. The API endpoint returns usage statistics only.

## Star

If you find this plugin useful, please give it a star on GitHub!