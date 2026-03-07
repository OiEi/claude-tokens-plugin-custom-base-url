# Claude Tokens Plugin

Lightweight Claude Code plugin that displays token usage in the status line.

## Structure

- `.claude-plugin/plugin.json` — plugin manifest
- `skills/setup/SKILL.md` — setup skill that configures status line in user settings
- `scripts/statusline.sh` — shell script that reads JSON from stdin and outputs formatted token info

## How it works

The status line script receives session data as JSON on stdin and outputs a colored summary.
No LLM calls are made — it's pure bash + jq.
