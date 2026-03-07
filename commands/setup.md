---
description: Configure Claude Code status line to display token usage
allowed-tools: [Read, Write, Edit, Bash]
---

# Setup Token Usage Status Line

Configure the Claude Code status line to show token usage, cost, and model info.

## Instructions

1. Read the current `~/.claude/settings.json` file (create it if it doesn't exist)
2. Add or update the `statusLine` key with the path to the status line script:

```json
{
  "statusLine": "PLUGIN_ROOT/scripts/statusline.sh"
}
```

Where `PLUGIN_ROOT` is the absolute path to the installed plugin directory. You can determine it by finding where this command file is located — the plugin root is two levels up from this file.

The plugin is installed at: `~/.claude/plugins/cache/claude-tokens-plugin/claude-tokens-plugin/1.0.0`

So the statusLine value should be: `~/.claude/plugins/cache/claude-tokens-plugin/claude-tokens-plugin/1.0.0/scripts/statusline.sh`

3. Write the updated JSON back to `~/.claude/settings.json`, preserving any existing settings
4. Make sure the script is executable: `chmod +x` on the statusline.sh path
5. Tell the user to restart Claude Code to see the token usage in the status line
