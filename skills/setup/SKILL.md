---
name: setup
description: Configure Claude Code status line to display token usage
user_invocable: true
---

# Setup Token Usage Status Line

Configure the Claude Code status line to show token usage, cost, and model info.

## Instructions

1. Read the current `~/.claude/settings.json` file (create it if it doesn't exist)
2. Add or update the `statusLine` key with the following value:

```json
{
  "statusLine": "${CLAUDE_PLUGIN_ROOT}/scripts/statusline.sh"
}
```

Where `${CLAUDE_PLUGIN_ROOT}` should be replaced with the actual absolute path to this plugin's root directory (the parent of the `skills/` directory).

3. Write the updated JSON back to `~/.claude/settings.json`, preserving any existing settings
4. Make sure `scripts/statusline.sh` is executable: `chmod +x <plugin_root>/scripts/statusline.sh`
5. Tell the user to restart Claude Code to see the token usage in the status line
