# claude-tokens-plugin

Lightweight Claude Code plugin that displays token usage, cost, and model info in the status line. Zero LLM token consumption — runs on pure bash + jq.

## Display

```
45% 125kt | $0.12 | Claude Sonnet 4
```

Color-coded by context usage:
- **Green**: < 50%
- **Yellow**: 50–80%
- **Red**: > 80%

## Installation

```bash
/plugin marketplace add jointime1/claude-tokens-plugin
/plugin install claude-tokens-plugin
```

## Setup

Run the setup skill to configure the status line:

```
/claude-tokens-plugin:setup
```

Then restart Claude Code. Token usage will appear in the status line.

## Requirements

- [jq](https://jqlang.github.io/jq/) must be installed and available in PATH
