# claude-tokens-plugin

Lightweight Claude Code plugin that displays plan usage limits and context window in the status line. Zero LLM token consumption — fetches data from Anthropic API via pure bash + jq + curl.

## Display

```
session 68% | weekly 17% | ctx 45%
```

With Russian locale:
```
сессия 68% | неделя 17% | контекст 45%
```

Color-coded:
- **Green**: < 50%
- **Yellow**: 50-80%
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
1. Reads context window data from stdin (provided by Claude Code)
2. Fetches plan usage (session/weekly limits) from `api.anthropic.com/api/oauth/usage` using your OAuth token
3. Caches API responses for 30 seconds
4. Outputs a color-coded summary line

No LLM calls are made. The API endpoint returns usage statistics only.

## Star

If you find this plugin useful, please give it a star on GitHub!
