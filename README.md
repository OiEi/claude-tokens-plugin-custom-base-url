# claude-tokens-plugin

Lightweight Claude Code plugin that displays plan usage limits and context window in the status line. Zero LLM token consumption — fetches data from Anthropic API via pure bash + jq + curl.

## Display

```
Sonnet 4.6 | session ━━━───── 37% 1h 45m | weekly ━━────── 21% 6d 5h | ctx ━──────── 10%
```

When API rate limit is hit, a notice appears at the start and cached data continues to be shown:
```
rate limit (no updates) | Sonnet 4.6 | session ━━━───── 37% 1h 45m | weekly ━━────── 21% 6d 5h | ctx ━──────── 10%
```

With Russian locale:
```
Sonnet 4.6 | сессия ━━━───── 37% 1ч 45м | неделя ━━────── 21% 6д 5ч | контекст ━──────── 10%
```

When rate limited:
```
рейт лимит (нет обновлений) | Sonnet 4.6 | сессия ━━━───── 37% 1ч 45м | неделя ━━────── 21% 6д 5ч | контекст ━──────── 10%
```

Color-coded:
- **Green**: < 50%
- **Yellow**: 50–80%
- **Red**: > 80%

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