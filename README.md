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

During install you'll be asked for an **Organisation path**:

- **Personal account** (gmail.com and other consumer domains): leave it empty.
- **Organisation account** (business email): paste the value shown at [app.xysq.ai/connect-agent](https://app.xysq.ai/connect-agent) — it looks like `/org/<your-org-id>`. Organisation accounts connect only through their organisation's endpoint; the personal endpoint refuses them.

To change it later, run `/plugin`, select **xysq**, and edit the setting.

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
| **Memory skill (`xysq`)** | Teaches Claude when and how to use xysq tools (retain, recall, reflect) |
| **Recall skills** | Five focused skills bundled from the xysq-skills library: `recap`, `decisions`, `actionables`, `blockers`, `prep` |

Skills are sourced from the [xysq-skills](https://github.com/xysq-ai/xysq-skills) submodule (`.skills-src`). To regenerate `skills/` after updating the submodule, run:

```bash
git submodule update --remote .skills-src
scripts/build-skills.sh
```

## Manual setup (alternative — for CI / headless contexts)

If you can't open a browser for OAuth (server-to-server automation, CI runners, shared workstations), use an API key:

1. At [app.xysq.ai/connect](https://app.xysq.ai/connect), generate a `xysq_...` API key.
2. Configure the MCP connection by hand:

```bash
claude mcp add xysq https://api.xysq.ai/mcp \
  --transport http \
  --header "Authorization: Bearer YOUR_API_KEY"
```

Organisation accounts must use their org-scoped URL instead of `/mcp`:

```bash
claude mcp add xysq https://api.xysq.ai/mcp/org/YOUR_ORG_ID \
  --transport http \
  --header "Authorization: Bearer YOUR_API_KEY"
```

Team scope is managed in the xysq web UI (the **MCP sync** toggle per team), not via connection config.

This path doesn't install the memory skill — use the plugin if you want it.

## Upgrading from v1.x

v1.x prompted for an API key during install. v2.0 uses OAuth instead — there's nothing to paste, the browser flow handles auth. v2.1 adds the **Organisation path** prompt (see Install above); organisation accounts should set it when re-enabling the plugin.

If you have v1.x installed:

```
/plugin update xysq
```

On your next MCP call, Claude Code will prompt you to authorise xysq in a browser. Your previously stored API key is no longer used by the plugin (you can revoke it at [app.xysq.ai/connect](https://app.xysq.ai/connect) if you don't need it for other tools).

## Links

- [xysq.ai](https://xysq.ai) — Learn more
- [app.xysq.ai](https://app.xysq.ai) — Manage your memories
- [Documentation](https://docs.xysq.ai) — Full docs
