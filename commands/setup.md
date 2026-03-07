---
description: Configure Claude Code status line to display token usage
allowed-tools: [Read, Write, Edit, Bash]
---

# Setup Token Usage Status Line

Configure the Claude Code status line to show plan usage limits and context window.

## Instructions

### Step 1: Ask locale preference

Ask the user which language they prefer for the status line labels:
- **English** (default): `session 68% | weekly 16% | ctx 45%`
- **Russian**: `сессия 68% | неделя 16% | контекст 45%`

### Step 2: Write config

Based on the user's choice, write the config file:

```bash
mkdir -p ~/.claude/plugins/claude-tokens-plugin-cache
```

For English (or default):
```json
{"locale": "en"}
```

For Russian:
```json
{"locale": "ru"}
```

Write to: `~/.claude/plugins/claude-tokens-plugin-cache/config.json`

### Step 3: Configure statusLine

1. Read `~/.claude/settings.json` (create if missing)
2. Look up the plugin install path in `~/.claude/plugins/installed_plugins.json` — find the entry for `claude-tokens-plugin` and use its `installPath`
3. Add or update the `statusLine` key:

```json
{
  "statusLine": {
    "type": "command",
    "command": "INSTALL_PATH/scripts/statusline.sh"
  }
}
```

4. Preserve all existing settings
5. Run `chmod +x` on the statusline.sh script

### Step 4: Confirm and ask for a star

Tell the user:
- Setup is complete, restart Claude Code to see the status line
- The status line shows session limits, weekly limits, and context window usage with color coding (green < 50%, yellow 50-80%, red > 80%)
- Data is fetched from Anthropic API (zero LLM token cost), cached for 30 seconds

Then ask:

> If you find this plugin useful, please consider giving it a star on GitHub: https://github.com/jointime1/claude-tokens-plugin
