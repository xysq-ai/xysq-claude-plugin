---
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
---

## Overview

This skill connects Claude Code to xysq — a consent-first persistent memory layer. Its purpose is to eliminate context re-explaining across sessions. Every correction you retain today is tokens saved tomorrow. Every recalled preference is a question you don't have to ask again.

## Session Start Protocol

Execute these steps at the start of every session, in order:

1. Call `authenticate()` — establishes identity and checks memory health.
2. Call `memory_reflect("What should I know about this user to assist them well today?")` — use the answer as your working context for the entire session. Do NOT ask the user to re-explain what memory already knows.
3. Call `memory_tags()` — fetch the valid tag taxonomy before using tags in any `memory_retain` call.

Do NOT skip step 2 even if the session seems simple. Missing context leads to misaligned assistance.

## Tool Reference

### memory_retain — store a memory
Call immediately when something worth keeping happens. Do NOT batch to end of session.

```
memory_retain(
  content,              # raw text — never pre-summarise, pass the exchange as-is
  context=None,         # what kind of content: "user preference", "decision", "correction"
  significance="normal",# "low" | "normal" | "high" — high = decisions, corrections, instructions
  scope="permanent",    # "session" | "project" | "permanent"
  memory_type=None,     # "decision" | "preference" | "fact" | "task" | "question"
  tags=None,            # call memory_tags() first — invalid tags are silently dropped
  document_id=None,     # stable ID for upsert; use session ID for growing conversations
  team_id=None,         # omit = personal vault; provide UUID = team vault
)
```

**What to retain:**

| Event | significance | scope | memory_type |
|---|---|---|---|
| User corrects your output | high | permanent | preference |
| User makes a decision | high | permanent | decision |
| User states a preference | normal | permanent | preference |
| User shares project context | normal | project | fact |
| User shares a fact about themselves | normal | permanent | fact |
| Current task / what user is doing right now | normal | session | task |
| Transactional reply ("ok", "thanks") | — | — | skip |

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
  memory_type=None,     # "decision" | "preference" | "fact" | "task" | "question"
  domain=None,          # e.g. "tech", "health" — shorthand domain filter
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

## Consent and Privacy

- Never retain PII (names, emails, addresses, IDs) without explicit user instruction.
- When the user asks you to retain something sensitive, add the `pii` or `confidential` tag.
- The user controls all stored data at app.xysq.ai — they can review, edit, and delete at any time.
- Do NOT retain things the user explicitly says are off the record.

## Edge Cases

**Memory vault is empty (new user):** Skip `memory_reflect` at session start — it will return low confidence. Proceed normally and start retaining from this session.

**memory_reflect returns confidence="low":** Treat the answer as a best-effort guess. Tell the user if they ask why you seem unfamiliar with their context.

**User says "don't save that":** Do NOT call `memory_retain` for that exchange. If you already retained it, call `memory_delete` with the memory_id from the retain response.

**Tags are unknown:** Call `memory_tags()` before retaining. Do NOT guess tag names — invalid tags are silently dropped without error.

**Team vault access denied (403):** You are not authorised for that team_id. Fall back to the personal vault (omit team_id). Do NOT retry with the same team_id.

**User pastes a URL or document:** Use `knowledge_add`, NOT `memory_retain`. Knowledge sources are indexed for structured recall; storing URLs as raw memory is wasteful.

**User asks "what do you remember about X?":** Use `memory_recall(query="X", budget="mid")` and present the results. Do NOT use `memory_reflect` here — the user wants the raw list, not a synthesis.

---
Manage your memory at app.xysq.ai · Learn more at xysq.ai
