---
name: xysq
description: >
  Connects Claude Code to xysq persistent memory. Activate this skill
  whenever the user asks to "remember", "recall", "forget", "what did I
  say about", "save this", "store this", or references past decisions,
  preferences, or project context. Also activate at the start of every
  session to pull user context, and immediately after any correction,
  decision, or stated preference to persist it.
  Do NOT activate for general coding questions that have no personal
  memory component. Do NOT activate for questions about xysq's own
  codebase unless the user explicitly asks to store or recall something.
trigger: always
---

## Overview

This skill connects Claude Code to xysq — a consent-first persistent memory layer. Its purpose is to eliminate context re-explaining across sessions. Every correction you retain today is tokens saved tomorrow. Every recalled preference is a question you don't have to ask again.

## Session Start Protocol

Do NOT fire a generic session-start reflect. User profile context is pre-baked into the "About you" section of this skill when available — treat that as your working context for the entire session.

On the user's **first substantive message** (not greetings like "hi", "hey", "you there?"):

1. Call `memory_recall(query=<user's message, shaped as a lookup>, budget="low")` — pulls relevant memories and wiki entries in parallel. Use the results as task-specific context before answering.
2. Call `authenticate()` lazily, on your first write (`memory_retain`, `memory_delete`, `knowledge_add`) — not at session start.
3. Call `memory_tags()` just before your first `memory_retain`, not at session start. Invalid tags are silently dropped, so fetch the taxonomy only when you're about to use it.

Call `memory_reflect` ONLY when the user's question itself requires synthesis across memory — "what do I prefer about X", "summarise my stance on Y", "compare my past decisions on Z". Not as warmup.

Skip both recall and reflect for: pure greetings, pure code-only questions with no personal signal, or follow-ups where the prior turn's recall already covered the ground.


## Tool Reference

### memory_retain — store a memory

```
memory_retain(
  content,              # canonical conversation format — see below
  context=None,         # describes the source: "Claude Code session — DB selection for payments"
  significance="normal",# "low" | "normal" | "high" — high = decisions, corrections, instructions
  scope="permanent",    # "session" | "project" | "permanent"
  tags=None,            # call memory_tags() first — invalid tags are silently dropped
  document_id=None,     # ⚠️ REQUIRED for quality. Mint once per new chat (uuid4() or
                        # "<client>:<session-id>") and reuse it on EVERY retain in that chat.
  team_id=None,         # omit = personal vault; provide UUID = team vault
)
```

**⚠️ RETAIN CADENCE — READ FIRST.**
Do NOT call `memory_retain` on the same turn you are about to generate a reply. Your reply does not yet exist in context at tool-call time, so there is no Assistant text to copy — the best you can do is hallucinate a summary of your future reply ("Provided guidance", "Explained the options"), which destroys recall quality. Instead, retain on the **NEXT** user turn, when both sides of the previous exchange are visible in your context and can be copied verbatim.

**⚠️ EXPLICIT SAVE COMMAND** ("remember this", "save that", "note this").
The save command is a **trigger, not the content**. Do NOT retain only the save command itself — useless. Retain the ENTIRE unsaved conversation so far: every User and Assistant turn from the start of this chat (or from your last `memory_retain` with the same `document_id`, whichever is later) up to and including the turn just *before* the save command. The save command itself should NOT appear in `content`.

**⚠️ VERBATIM COPY RULE.**
Both the User and Assistant lines in `content` MUST be literal, character-for-character copies from your context window. DO NOT paraphrase. DO NOT describe ("provided guidance", "offered help", "explained X" — all WRONG). DO NOT truncate. If your reply was 2000 words, the Assistant line contains 2000 words.

**⚠️ `document_id` is the single most important field for quality.** Mint one per new chat, reuse it for every retain in that chat. Omitting it orphans each retain as its own document. New topic (coding → travel) = new `document_id`; subtopic drift within one domain = same id. Stateless clients: `uuid4()` at minimum.

**`content` format — canonical line shape:**

```
User (2026-04-22T10:00:00Z): <exact text the user typed>
Assistant (2026-04-22T10:00:12Z): <exact text of the prior reply, verbatim>
```

Role capitalised, ISO timestamp in parentheses, colon, FULL turn text. Separate turns with "
". On first retain of a chat: full conversation so far. On subsequent retains (same `document_id`): only NEW turns since the last retain.

**CORRECT example** (Assistant line is the actual prior reply):

```
User (2026-04-22T00:00:00Z): I want to research distribution channels for launching a startup with low budget. Can you help?
Assistant (2026-04-22T00:00:05Z): Absolutely — let's break this into three tracks. For low-budget distribution: 1) Direct-to-community via Reddit, Discord, Indie Hackers — pick two subreddits your users live in and post weekly value before ever mentioning your product. 2) Cold outbound: 20 personalised emails/day beats 200 templated ones. 3) Content SEO targeting long-tail queries your competitors ignore...
```

**WRONG — never do this:**

```
Assistant (2026-04-22T00:00:05Z): Provided structured guidance and offered help.
Assistant (2026-04-22T00:00:05Z): Explained distribution channel options.
```

These store ZERO recoverable information. Non-conversation content (pasted doc / code / note): pass raw as-is, no formatting needed.

**What to retain:**

| Event | significance | scope |
|---|---|---|
| User corrects your output | high | permanent |
| User makes a decision | high | permanent |
| User states a preference | normal | permanent |
| User shares project context | normal | project |
| User shares a fact about themselves | normal | permanent |
| Current task / what user is doing right now | normal | session |
| Transactional reply ("ok", "thanks") | — | skip |

**Rule:** if in doubt, retain. Under-capturing costs more than over-capturing.

---

### memory_reflect — ask a question, get a direct answer
Use this when you want a synthesised, ready-to-use answer from memory.

```
memory_reflect(
  query,              # natural-language question
  budget="mid",       # "low" | "mid" | "high" — use high for broad historical questions
  write_back=False,   # True = cache this synthesis in the wiki for faster future recall
  team_id=None,
)
# Returns: { answer, confidence, sources, wiki_context_used }
# Use answer directly — do NOT call memory_recall for the same question.
```

---

### memory_recall — retrieve raw facts to reason over yourself
Use when you need source material to process yourself, not a pre-synthesised answer.

```
memory_recall(
  query,
  budget="mid",         # "low" | "mid" | "high"
  intent=None,          # "decision" | "preference" | "fact" | "context"
  scope=None,           # "session" | "project" | "permanent"
  domain=None,          # e.g. "tech", "health" — shorthand for tags=["domain:<value>"]
  mood=None,            # e.g. "focused", "frustrated" — shorthand for tags=["mood:<value>"]
  team_id=None,
)
```

Do NOT call memory_recall then memory_reflect for the same question. Pick one.

---

### knowledge_add — save an external source
Use when the user pastes a link, document, code snippet, or chat transcript.

```
knowledge_add(
  type,                # "link" | "quote" | "code" | "chat"
  url=None,            # required for type="link"
  content=None,        # required for type="quote" | "code" | "chat"
  title=None,
  confidence="medium", # "high" | "medium" | "low"
  location=None,       # e.g. "p. 47", "src/auth.py:12-40"
  session_context=None,# what the conversation was about
  team_id=None,
)
```

Do NOT use memory_retain for URLs or pasted documents — use knowledge_add.

---

### memory_tags — fetch valid tag taxonomy
Call once per session before using tags in memory_retain. Invalid tags are silently dropped.

```
memory_tags()  # returns grouped tag definitions
```

---

### list_teams — find team IDs
```
list_teams()  # returns id, name, role for each team
# Use team id in any memory tool to read/write the team vault instead of personal vault
```

---

### memory_list — browse recent memories
```
memory_list(limit=20, team_id=None)
```

### memory_delete — permanently remove a memory
```
memory_delete(memory_id, team_id=None)  # requires admin or owner role for team vaults
```

### skill_sync — update this skill file
```
skill_sync()  # fetches the latest xysq skill and returns install_path + content
# For Claude Code: write content to install_path using the Write tool
```


## Consent and Privacy

- Never retain PII (names, emails, addresses, IDs) without explicit user instruction.
- When the user asks you to retain something sensitive, add the `pii` or `confidential` tag.
- The user controls all stored data at app.xysq.ai — they can review, edit, and delete at any time.
- Do NOT retain things the user explicitly says are off the record.


## Edge Cases

**Memory vault is empty (new user):** `memory_recall` returns few or no results. Proceed normally and start retaining from this session.

**memory_recall returns nothing relevant:** Proceed with the user's question directly. Do NOT fall back to a generic `memory_reflect` — absence of recall hits means there's nothing useful in memory for this query.

**memory_reflect returns confidence="low":** Treat the answer as a best-effort guess. Tell the user if they ask why you seem unfamiliar with their context.

**User says "don't save that":** Do NOT call `memory_retain` for that exchange. If you already retained it, call `memory_delete` with the memory_id from the retain response.

**Tags are unknown:** Call `memory_tags()` just before retaining. Do NOT guess tag names — invalid tags are silently dropped without error.

**Team vault access denied (403):** You are not authorised for that team_id. Fall back to the personal vault (omit team_id). Do NOT retry with the same team_id.

**User pastes a URL or document:** Use `knowledge_add`, NOT `memory_retain`. Knowledge sources are indexed for structured recall; storing URLs as raw memory is wasteful.

**User asks "what do you remember about X?":** Use `memory_recall(query="X", budget="mid")` and present the results. Do NOT use `memory_reflect` here — the user wants the raw list, not a synthesis.


---
Manage your memory at app.xysq.ai · Learn more at xysq.ai

