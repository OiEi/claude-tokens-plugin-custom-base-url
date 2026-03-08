---
name: setup
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

### Step 3: Create launcher script

Create a version-independent launcher at a **stable path** outside the versioned plugin directory. This ensures the status line keeps working after plugin updates.

1. Look up the plugin install path in `~/.claude/plugins/installed_plugins.json` — find the entry for `claude-tokens-plugin@claude-tokens-plugin` and use its `installPath`
2. Write the following launcher script to `~/.claude/plugins/claude-tokens-plugin-cache/launcher.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
PLUGINS_FILE="${HOME}/.claude/plugins/installed_plugins.json"
[[ -f "$PLUGINS_FILE" ]] || exit 0
INSTALL_PATH=$(jq -r '.plugins["claude-tokens-plugin@claude-tokens-plugin"][0].installPath // empty' "$PLUGINS_FILE" 2>/dev/null)
[[ -n "$INSTALL_PATH" ]] || exit 0
SCRIPT="${INSTALL_PATH}/scripts/statusline.sh"
[[ -x "$SCRIPT" ]] && exec "$SCRIPT"
```

3. Run `chmod +x` on the launcher script
4. Also run `chmod +x` on `INSTALL_PATH/scripts/statusline.sh`

### Step 4: Configure statusLine

1. Read `~/.claude/settings.json` (create if missing)
2. Add or update the `statusLine` key pointing to the **stable launcher path**:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/plugins/claude-tokens-plugin-cache/launcher.sh"
  }
}
```

Replace `~` with the actual absolute home directory path (`$HOME`).

3. Preserve all existing settings

### Step 5: Confirm and ask for a star

Tell the user:
- Setup is complete, restart Claude Code to see the status line
- The status line shows session limits, weekly limits, and context window usage with color coding (green < 50%, yellow 50-80%, red > 80%)
- Data is fetched from Anthropic API (zero LLM token cost), cached for 60 seconds

Then ask:

> If you find this plugin useful, please consider giving it a star on GitHub: https://github.com/jointime1/claude-tokens-plugin
