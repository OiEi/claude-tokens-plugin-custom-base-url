---
description: Configure Claude Code status line to display token usage
allowed-tools: [Read, Write, Edit, Bash]
---

# Setup Token Usage Status Line

Configure the Claude Code status line to show token usage, cost, and model info.

## Instructions

1. Read the current `~/.claude/settings.json` file (create it if it doesn't exist)
2. Add or update the `statusLine` key with an object:

```json
{
  "statusLine": {
    "type": "command",
    "command": "PLUGIN_ROOT/scripts/statusline.sh"
  }
}
```

Where `PLUGIN_ROOT` is the absolute path to the installed plugin directory. Find it by looking up the plugin in `~/.claude/plugins/installed_plugins.json` — the `installPath` field has the path.

3. Write the updated JSON back to `~/.claude/settings.json`, preserving any existing settings
4. Make sure the script is executable: `chmod +x` on the statusline.sh path
5. Tell the user to restart Claude Code to see the token usage in the status line
