# xysq — Claude Code Plugin

Persistent memory for AI agents. Install this plugin to give Claude Code access to your xysq memory vault — remember decisions, preferences, and context across every session.

## Install

### 1. Get your API key

Sign in at [app.xysq.ai](https://app.xysq.ai/login) and click **Connect Agent** to generate an API key.

### 2. Install the plugin

In Claude Code, run:

```
/plugin install xysq-ai/xysq-claude-plugin
```

Or add as a marketplace first:

```
/plugin marketplace add xysq-ai/xysq-claude-plugin
/plugin install xysq
```

### 3. Enter your API key

Claude Code will prompt for your xysq API key. Paste the `xysq_...` key you generated. It's stored securely in your system keychain.

### 4. Done

Start a new session. The plugin auto-connects to xysq and loads the memory skill. Try:

```
Remember that I prefer dark mode in all my tools.
```

## What's included

| Component | Purpose |
|-----------|---------|
| **MCP server config** | Auto-connects to `api.xysq.ai/mcp` with your API key |
| **Memory skill** | Teaches Claude when and how to use xysq tools (retain, recall, reflect) |

## Manual setup (alternative)

If you prefer not to use the plugin, you can connect manually:

```bash
claude mcp add xysq https://api.xysq.ai/mcp --header "Authorization: Bearer YOUR_API_KEY"
```

This configures the MCP connection but does not install the skill file.

## Links

- [xysq.ai](https://xysq.ai) — Learn more
- [app.xysq.ai](https://app.xysq.ai) — Manage your memories
- [Documentation](https://docs.xysq.ai) — Full docs
