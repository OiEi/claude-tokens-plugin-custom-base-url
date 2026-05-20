# claude-tokens-plugin (Custom Fork)

Fork of [jointime1/claude-tokens-plugin](https://github.com/jointime1/claude-tokens-plugin) with support for custom API endpoints and authorization tokens.

Lightweight Claude Code plugin that displays plan usage limits and context window in the status line. Zero LLM token consumption — fetches data from custom API via pure bash + jq + curl.

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

```bash
/plugin marketplace add OiEi/claude-tokens-plugin-custom-base-url
/plugin install claude-tokens-plugin
```

## Setup

### For Original Anthropic API

Run the setup command to configure the status line:

```bash
/setup
```

It will ask your preferred language (English/Russian), configure `~/.claude/settings.json`, and you're done. Restart Claude Code to see the status line.

### For Custom API Endpoint

Edit `~/.claude/plugins/claude-tokens-plugin-cache/config.json`:

```json
{
  "locale": "en",
  "base_url": "https://api.your-service.com",
  "quota_endpoint": "/api/monitor/usage/quota/limit",
  "auth_token": "your_auth_token_here"
}
```

Or use environment variables:

```bash
export ANTHROPIC_AUTH_TOKEN="your_auth_token_here"
```

The plugin will automatically transform custom API formats to the expected format. It looks for:
- `data.limits` array with `TOKENS_LIMIT` type
- Short-term limits (session)
- Long-term limits (weekly)

## Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `locale` | Language preference (en/ru) | en |
| `base_url` | Custom API base URL | https://api.anthropic.com |
| `quota_endpoint` | Custom quota monitoring endpoint | /api/oauth/usage |
| `auth_token` | Custom authorization token | (uses OAuth token) |

## Requirements

- [jq](https://jqlang.github.io/jq/)
- [curl](https://curl.se/)

## How it works

The status line script:
1. Reads context window data and model info from stdin (provided by Claude Code)
2. Fetches plan usage (session/weekly limits) from configured API endpoint
3. Token priority: `ANTHROPIC_AUTH_TOKEN` env var → `auth_token` config → OAuth token from keychain
4. Caches API responses for 60 seconds; on rate limit error waits 2 minutes before retrying
5. Transforms custom API formats to expected format automatically
6. Outputs a colour-coded summary line with progress bars and reset countdowns

No LLM calls are made. The API endpoint returns usage statistics only.

## Star

If you find this plugin useful, please give it a star on GitHub!

## Original

This is a fork of [jointime1/claude-tokens-plugin](https://github.com/jointime1/claude-tokens-plugin).