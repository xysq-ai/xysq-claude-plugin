# xysq — Claude Code Plugin

**The official Claude Code plugin from [xysq](https://xysq.ai).**

Persistent memory for AI agents. Install this plugin to give Claude Code access to your xysq memory vault — remember decisions, preferences, and context across every session.

## Install

### 1. Add the xysq marketplace

In Claude Code, run:

```
/plugin marketplace add xysq-ai/xysq-claude-plugin
```

### 2. Install the plugin

```
/plugin install xysq
```

Claude Code opens a browser window to sign you in to xysq. Approve the connection — no API key to copy, no config to edit. The session is stored securely in your system keychain.

### 3. Done

Start a new session. Try:

```
Remember that I prefer dark mode in all my tools.
```

## Working with teams

Once you're signed in, configure team scope in your xysq web UI — no plugin reinstall needed:

1. Open [app.xysq.ai/teams](https://app.xysq.ai/teams).
2. Flip the **MCP sync** toggle on for any team you want Claude Code to write to and read from.
3. Your next memory call will fan out to your personal vault plus every toggled team.

Toggling on or off takes effect on the next MCP tool call. See [Teams via MCP](https://docs.xysq.ai/features/teams-mcp) for the full mental model.

## What's included

| Component | Purpose |
|-----------|---------|
| **MCP server config** | OAuth-authorised connection to `api.xysq.ai/mcp` as your xysq user |
| **Memory skill** | Teaches Claude when and how to use xysq tools (retain, recall, reflect) |

## Manual setup (alternative — for CI / headless contexts)

If you can't open a browser for OAuth (server-to-server automation, CI runners, shared workstations), use an API key:

1. At [app.xysq.ai/connect](https://app.xysq.ai/connect), generate a `xysq_...` API key.
2. Configure the MCP connection by hand:

```bash
claude mcp add xysq https://api.xysq.ai/mcp \
  --transport http \
  --header "Authorization: Bearer YOUR_API_KEY"
```

For team scope on API-key sessions, add `--header "X-Xysq-Teams: TEAM_UUID_1,TEAM_UUID_2"`. The UI **MCP sync** toggle applies only to OAuth sessions.

This path doesn't install the memory skill — use the plugin if you want it.

## Upgrading from v1.x

v1.x prompted for an API key during install. v2.0 uses OAuth instead — there's nothing to paste, the browser flow handles auth.

If you have v1.x installed:

```
/plugin update xysq
```

On your next MCP call, Claude Code will prompt you to authorise xysq in a browser. Your previously stored API key is no longer used by the plugin (you can revoke it at [app.xysq.ai/connect](https://app.xysq.ai/connect) if you don't need it for other tools).

## Links

- [xysq.ai](https://xysq.ai) — Learn more
- [app.xysq.ai](https://app.xysq.ai) — Manage your memories
- [Documentation](https://docs.xysq.ai) — Full docs
