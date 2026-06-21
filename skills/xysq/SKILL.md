---
name: xysq
description: >
  xysq is the persistent memory substrate for AI agents. With this skill
  active, Claude retains, recalls, and reasons over the user's decisions,
  preferences, project context, and prior conversations across sessions,
  so they never re-explain themselves.

  TRIGGER when:
  - User says "remember", "save", "note", "forget", "recall", "what did I
    say about", "what do you know about me / X".
  - User states a preference, makes a decision, corrects you, or shares a
    fact about themselves, their project, tools, or team, even in passing.
  - User mentions a project, codebase, person, or context by name Claude
    should already know, recall first, ask second.
  - First substantive message of any session, prime with memory_recall.
  - Problem is under-specified but references user/project context Claude
    lacks ("fix the auth bug", "draft a reply to my CEO"), recall once.
  - User pastes a URL, quote, code snippet, or chat transcript, use
    memory_retain with source:knowledge + source_type:* tags. For binary
    or long files (>10 KB), use organise_upload_file instead.

  SKIP when:
  - Pure greetings ("hi", "hey").
  - One-off coding questions with no personal/project signal ("syntax for
    async/await in Python").
  - Questions about xysq's own product or codebase, unless the user asks
    to store or recall something.

  Default operating mode whenever xysq is connected. Invoke generously,
  under-capturing costs the user more than over-capturing.
allowed-tools:
  - mcp__xysq__authenticate
  - mcp__xysq__whoami
  - mcp__xysq__memory_retain
  - mcp__xysq__memory_recall
  - mcp__xysq__memory_reflect
  - mcp__xysq__memory_list
  - mcp__xysq__memory_delete
  - mcp__xysq__memory_tags
  - mcp__xysq__memory_get_document
  - mcp__xysq__memory_get_chunk
  - mcp__xysq__list_teams
  - mcp__xysq__organise_list_folders
  - mcp__xysq__organise_get_folder
  - mcp__xysq__organise_create_folder
  - mcp__xysq__organise_rename_folder
  - mcp__xysq__organise_move_folder
  - mcp__xysq__organise_delete_folder
  - mcp__xysq__organise_upload_file
---

## Overview

This skill connects Claude Code to xysq - a consent-first persistent memory layer. Its purpose is to eliminate context re-explaining across sessions. Every correction you retain today is tokens saved tomorrow. Every recalled preference is a question you don't have to ask again.

Every session without memory starts cold. The user re-explains their stack, restates their preferences, recaps last week's decisions. That re-explanation is the single largest waste in any AI workflow - measured in tokens, in time, and in the user's patience.

xysq is the substrate that ends that waste. The user has already consented to memory and given you the keys. Your job is to make that consent pay off: prime cold sessions with recall, recognise memory-worthy moments and retain them verbatim, and reason over prior context the way a colleague who has worked with this person for months would.

Treat this skill as the default operating mode, not a tool you reach for occasionally. Memory is a substrate, not a feature.


## Session Start Protocol

Do NOT fire a generic session-start reflect just to warm up. Recall is on-demand: pull context when the user's actual task needs it (see Proactive recall below).

On the user's **first substantive message** (not greetings like "hi", "hey", "you there?"):

1. Call `memory_recall(query=<user's message, shaped as a lookup>, budget=<see budget rule below>)` - pulls relevant memories from the user's bank. Use the results as task-specific context before answering.
2. Call `authenticate()` lazily, on your first write (`memory_retain`, `memory_delete`, `organise_upload_file`) - not at session start.
3. Call `memory_tags()` just before your first `memory_retain`, not at session start. Invalid tags are silently dropped, so fetch the taxonomy only when you're about to use it.

Call `memory_reflect` when a question needs facts gathered across memory and you will synthesize the answer - "what do I prefer about X", "summarise my stance on Y", "compare my past decisions on Z". It returns facts (plus a convenience digest), not a finished answer. Not as warmup.

Skip both recall and reflect for: pure greetings, pure code-only questions with no personal signal, or follow-ups where the prior turn's recall already covered the ground.

## Proactive recall - the second-biggest leverage point

Reactive recall (user says "remember when") is easy. Proactive recall is what separates a memory-augmented Claude from a stateless one: noticing that a problem is under-specified and that memory probably contains the missing constraint.

**Recall proactively when both signals are present:**

1. **The problem references entities the user expects you to know** - a project name, a person, "my X", "our Y", "the Z we discussed". These are linguistic tells that the user has already mentally loaded the context and assumes you have too.
2. **The answer quality depends on personal/project specifics, not general knowledge.** "What's the syntax for async/await" → no recall. "How should I structure my async logic" → recall, because the right answer depends on the user's codebase, framework, and past decisions.

**Example - proactive recall pays off:**

> User: "help me fix the auth bug we hit yesterday"

Both signals present: "the auth bug" expects prior knowledge, and the fix depends on the user's stack. Call `memory_recall(query="auth bug yesterday", budget="mid")` before asking what stack they're on.

**Example - proactive recall is wasteful:**

> User: "what's the difference between Python's `is` and `==`?"

Neither signal present. General knowledge, no personal context. Answer directly.

**Anti-trigger - don't fish.** Recall is NOT a substitute for asking a clarifying question. If recall returns nothing relevant for an ambiguous prompt, ask the user - don't recall again with a different query hoping something hits. Fishing burns tokens without producing answers.

**Batch within a problem.** Recall once at the start of a problem, not repeatedly through the thread. If you already recalled in turn 1 of a 5-turn debug session, don't recall again on turn 3 unless the domain has shifted (coding → travel).

**Budget rule:**
- Explicit user ask ("what do you know about my project?") → `budget="high"`. The user is explicitly asking - pay for quality.
- Proactive recall (under-specified problem) → `budget="mid"`. Good signal-to-noise without being expensive.
- Reserve `budget="low"` for follow-up recalls within an already-recalled thread.

## Explicit save commands

When the user says "remember this", "save that", "note this" - the save command is a **trigger, not the content**. Do NOT retain only the save command itself; retain the ENTIRE unsaved conversation so far. See `memory_retain` below for the exact content format and `document_id` rules.


## Tool Reference

### memory_retain - store a memory

```
memory_retain(
  content,              # canonical conversation format - see below
  context=None,         # describes the source: "Claude Code session - DB selection for payments"
  significance="normal",# "low" | "normal" | "high" - high = decisions, corrections, instructions
  scope="permanent",    # "session" | "project" | "permanent"
  tags=None,            # call memory_tags() first - invalid tags are silently dropped
  document_id=None,     # omit on the FIRST retain of a chat - the server mints one
                        # and returns it. Echo that exact id on later retains (see below).
  team_id=None,         # omit = personal vault; provide UUID = team vault
)
```

**⚠️ RETAIN CADENCE - READ FIRST.**
Do NOT call `memory_retain` on the same turn you are about to generate a reply. Your reply does not yet exist in context at tool-call time, so there is no Assistant text to copy - the best you can do is hallucinate a summary of your future reply ("Provided guidance", "Explained the options"), which destroys recall quality. Instead, retain on the **NEXT** user turn, when both sides of the previous exchange are visible in your context and can be copied verbatim.

**⚠️ EXPLICIT SAVE COMMAND** ("remember this", "save that", "note this").
The save command is a **trigger, not the content**. Do NOT retain only the save command itself - useless. Retain the ENTIRE unsaved conversation so far: every User and Assistant turn from the start of this chat (or from your last `memory_retain` with the same `document_id`, whichever is later) up to and including the turn just *before* the save command. The save command itself should NOT appear in `content`.

**⚠️ VERBATIM COPY RULE.**
Both the User and Assistant lines in `content` MUST be literal, character-for-character copies from your context window. DO NOT paraphrase. DO NOT describe ("provided guidance", "offered help", "explained X" - all WRONG). DO NOT truncate. If your reply was 2000 words, the Assistant line contains 2000 words.

**⚠️ `document_id` is the single most important field for quality, and the server owns it - you do not mint it.**
- First retain of a chat: omit `document_id`. The server mints one and returns it in the response.
- Every later retain in the same topic: pass that exact returned `document_id` back, so facts cluster into one document and recall stays sharp.
- Real topic drift (coding → travel): omit `document_id` again; the server mints a fresh one and returns it. Use that one going forward. Subtopic drift within one domain (Python → Node while coding) is NOT drift - keep the same id.

**`content` format - canonical line shape:**

```
User (2026-04-22T10:00:00Z): <exact text the user typed>
Assistant (2026-04-22T10:00:12Z): <exact text of the prior reply, verbatim>
```

Role capitalised, ISO timestamp in parentheses, colon, FULL turn text. Separate turns with "
". On first retain of a chat: full conversation so far. On subsequent retains (same `document_id`): only NEW turns since the last retain.

**CORRECT example** (Assistant line is the actual prior reply):

```
User (2026-04-22T00:00:00Z): I want to research distribution channels for launching a startup with low budget. Can you help?
Assistant (2026-04-22T00:00:05Z): Absolutely - let's break this into three tracks. For low-budget distribution: 1) Direct-to-community via Reddit, Discord, Indie Hackers - pick two subreddits your users live in and post weekly value before ever mentioning your product. 2) Cold outbound: 20 personalised emails/day beats 200 templated ones. 3) Content SEO targeting long-tail queries your competitors ignore...
```

**WRONG - never do this:**

```
Assistant (2026-04-22T00:00:05Z): Provided structured guidance and offered help.
Assistant (2026-04-22T00:00:05Z): Explained distribution channel options.
```

These store ZERO recoverable information. Non-conversation content (pasted doc / code / note): pass raw as-is, no formatting needed.

**Recognising memory-worthy moments - the implicit triggers**

The user will rarely say "remember this." The high-leverage retains happen when you notice a memory-worthy moment in passing and capture it without being asked. Train yourself to recognise these patterns:

| Moment in conversation | What to retain | significance | scope |
|---|---|---|---|
| User makes a decision ("we're going with Postgres over MongoDB because…") | The decision + the reasoning | high | project |
| User corrects your output ("no, I prefer integration tests over mocks") | The correction as a preference | high | permanent |
| User states a preference in passing ("I always use Tailwind for styling") | The preference | normal | permanent |
| User shares project context ("our deploy pipeline runs on Cloud Run") | Project fact | normal | project |
| User shares a fact about themselves ("I'm the only backend engineer on this team") | Personal fact | normal | permanent |
| User describes current task ("today I'm migrating from Firebase to Supabase") | Session context | normal | session |
| User mentions a tool, library, or service they use regularly | Stack fact | normal | project or permanent |
| Transactional reply ("ok", "thanks") | - | - | skip |

**Rule:** if in doubt, retain. Under-capturing costs the user more than over-capturing - every retained correction is a question they won't have to answer again next session.

---

### memory_reflect - gather facts to synthesize
Read the returned facts and synthesize the answer yourself; the answer field is a convenience digest of those facts. Contradictions are resolved among the returned observation facts (e.g. an older preference superseded by a newer one returns as a reconciled, temporally-aware fact).

```
memory_reflect(
  query,              # natural-language question
  budget="mid",       # "low" | "mid" | "high" - use high for broad historical questions
  response_schema=None,
  tags=None,          # optional tag filter, e.g. ["source:knowledge"]
  team_id=None,
)
# Returns: {
#   answer:     "...",                       # convenience digest of the facts
#   confidence: "high" | "medium" | "low",
#   citations:  [{id, type, context,
#                 occurred_start, occurred_end}, ...],
# }
```

The ``answer`` field is a convenience digest of the returned facts. For follow-up "where did you get that?" questions, pass a citation's ``id`` (or its document_id) to ``memory_get_document``.

Do NOT call memory_recall after memory_reflect for the same question - both return facts; memory_reflect adds a digest plus observation-resolution, memory_recall gives raw history.

---

### memory_recall - retrieve raw facts to reason over yourself
Use when you need source material to reason over yourself (e.g. history queries - "what did the user say about X"). For "what's true now / what does the user prefer" - call ``memory_reflect`` (it returns observation-resolved facts to synthesize), or pass ``types=["observation"]`` to recall directly.

```
memory_recall(
  query,
  budget="low",         # default - fast and cheap. Raise for deep dives.
  types=None,           # omit for raw history. Pass ["observation"] for
                        # conflict-resolved "what's true now" facts only.
  tags=None,            # free-form tag filter, e.g. ["source:knowledge"]
  tags_match="any",     # "any" | "all" | "any_strict" | "all_strict"
  max_tokens=2000,      # response size cap - raise (e.g. 8000) for deep dives
  query_timestamp=None, # ISO 8601 anchor for "last week"-style queries
  scope=None,           # "session" | "project" | "permanent"
  domain=None,          # shorthand for tags=["domain:<value>"]
  mood=None,            # shorthand for tags=["mood:<value>"]
  team_id=None,
)
```

Do NOT call memory_recall then memory_reflect for the same question. Pick one.

---

### memory_get_document - fetch a stored document by id
Use after ``memory_reflect`` returns citations (each carries a document_id) and the user asks for the source. Returns the document's ``original_text`` + tags + metadata.

```
memory_get_document(document_id, team_id=None)
```

### memory_get_chunk - fetch the raw source-text chunk
Use when a ``memory_recall`` result row has a ``chunk_id`` and you want the surrounding passage (not just the extracted fact). Chunks are bigger than facts; use sparingly.

```
memory_get_chunk(chunk_id)
```

---

### Saving external sources - use memory_retain with source tags

When the user pastes a link, quote, code snippet, or chat transcript, save
it via ``memory_retain`` with the ``source:knowledge`` tag plus a
``source_type:*`` tag:

```
memory_retain(
  content="...",                                       # the URL, quote, code, transcript
  tags=["source:knowledge", "source_type:link"],       # or quote / code / chat
  metadata={"url": "...", "title": "..."},             # type-specific fields go in metadata
  ...
)
```

Per source_type, put these in ``metadata``:
- ``link``:  ``{"url": "...", "title": "..."}``
- ``quote``: ``{"title": "...", "location": "p. 47"}``
- ``code``:  ``{"language": "python", "location": "src/auth.py:12-40"}``
- ``chat``:  ``{"title": "..."}``

For binary files or long documents (>10 KB), use ``organise_upload_file``
instead - it handles GCS storage and extraction.

---

### memory_tags - fetch valid tag taxonomy
Call once per session before using tags in memory_retain. Invalid tags are silently dropped.

```
memory_tags()  # returns grouped tag definitions
```

---

### list_teams - find team IDs
```
list_teams()  # returns id, name, role for each team
# Use team id in any memory tool to read/write the team vault instead of personal vault
```

---

### memory_list - browse recent memories
```
memory_list(limit=20, team_id=None)
```

### memory_delete - permanently remove a memory document
```
memory_delete(document_id, team_id=None)  # whole document; needs admin/owner for team vaults
# document_id comes from the retain response or a recall result row.
```

---

## Organise - folders + uploaded files

The Organise tools let you save the user's documents (Markdown notes, PDFs, CSVs, images, JSON, plain text) into a folder tree the user can later browse at app.xysq.ai. Uploaded files are automatically extracted and indexed so their content surfaces through `memory_recall` and `memory_reflect` afterwards.

**Use `organise_upload_file` when:** the user hands you a document, pastes a long note, or asks you to save a file - anything they'd recognise as "a file" rather than a quick fact.

**Use `memory_retain` instead when:** the user is sharing a fact, decision, preference, or short note from the conversation. Memory is cheaper and more searchable for granular content.

**For bare URLs:** there is no MCP add tool post-Phase-3. Direct the user to the xysq dashboard's Knowledge Base page.

### organise_list_folders - see the folder tree
```
organise_list_folders(team_id=None)
# Returns: { folders: [{ id, name, parent_id, path, is_system, chat_id }, ...] }
```
Call this before `organise_upload_file` if you need to pick the right destination folder. The vault root has `parent_id=None`; the system `/Chats/` folder has `is_system=true` and rejects direct uploads.

### organise_get_folder - inspect one folder
```
organise_get_folder(folder_id, team_id=None)
# Returns: { folder, children }  (children = subfolders, not files)
```

### organise_create_folder - make a new folder
```
organise_create_folder(name, parent_id=None, team_id=None)
# Returns: { folder: { id, name, ... } }
```
Omit `parent_id` to create directly under the vault root. Names must be unique among siblings; duplicate returns `status="conflict"`. Cannot nest under the system `/Chats/` folder.

### organise_rename_folder / organise_move_folder
```
organise_rename_folder(folder_id, name, team_id=None)
organise_move_folder(folder_id, new_parent_id, team_id=None)
```
System folders (root, `/Chats/`) cannot be renamed or moved. Moving a folder into one of its own descendants returns `status="error"` (cycle).

### organise_delete_folder - ⚠️ irreversible
```
organise_delete_folder(folder_id, forget_memories=False, team_id=None)
# Returns: { deleted_assets: <int> }
```
Cascades: every subfolder + file under it is removed. Set `forget_memories=True` to also purge extracted facts from recall (default leaves memory content intact). **Confirm with the user before deleting any non-empty folder.**

### organise_upload_file - save a document
```
organise_upload_file(
  filename,         # e.g. "notes.md", "contract.pdf"
  content_b64,      # standard base64 of the raw bytes (NOT a data: URL)
  mime_type,        # "text/markdown" | "text/plain" | "application/pdf" |
                    # "application/json" | "text/csv" | "image/png" | ...
  folder_id=None,   # omit to upload to the vault root
  team_id=None,
)
# Returns: { asset_id, filename, folder_id, mime_type, size_bytes, extraction_status }
```

**Encoding:**
- TEXT (markdown, txt, json, csv): `base64(utf-8-encoded text)`.
- BINARY (pdf, images): `base64(raw bytes)`.

**Limits:** 10 MB per file; only the MIME types listed above are accepted. Filename collisions get a " (2)", " (3)", … suffix automatically - use the returned `filename` when echoing back to the user. After upload, `extraction_status` is `"processing"`; the file is immediately browsable in Organise but only enters recall once extraction completes. There is no folder-upload primitive - for a tree of files, walk the structure yourself with `organise_create_folder` + `organise_upload_file` calls.


## Consent and Privacy

- Never retain PII (names, emails, addresses, IDs) without explicit user instruction.
- When the user asks you to retain something sensitive, add the `pii` or `confidential` tag.
- The user controls all stored data at app.xysq.ai - they can review, edit, and delete at any time.
- Do NOT retain things the user explicitly says are off the record.


## Edge Cases

**Memory vault is empty (new user):** `memory_recall` returns few or no results. Proceed normally and start retaining from this session.

**memory_recall returns nothing relevant:** Proceed with the user's question directly. Do NOT fall back to a generic `memory_reflect`, and do NOT recall again with a different query hoping something hits - absence of recall hits means there's nothing useful in memory for this query. Fishing burns tokens without producing answers. Ask the user instead.

**memory_reflect returns confidence="low":** Treat the answer as a best-effort guess. Tell the user if they ask why you seem unfamiliar with their context.

**User says "don't save that":** Do NOT call `memory_retain` for that exchange. If you already retained it, call `memory_delete` with the `document_id` from the retain response.

**Tags are unknown:** Call `memory_tags()` just before retaining. Do NOT guess tag names - invalid tags are silently dropped without error.

**Team vault access denied (403):** You are not authorised for that team_id. Fall back to the personal vault (omit team_id). Do NOT retry with the same team_id.

**User pastes a URL, quote, code snippet, or chat transcript:** Use `memory_retain` with `tags=["source:knowledge", "source_type:link"]` (or `quote`/`code`/`chat`) and put `url` / `title` / `location` in `metadata`. For binary or long files (>10 KB), use `organise_upload_file` - those land as memories with `kind=asset`.

**User asks "what do you remember about X?":** Use `memory_recall(query="X", budget="mid")` and present the results. Either tool returns facts; recall is the direct path for a raw list.

**File over 10 MB:** `organise_upload_file` returns `status="rejected"` with a size message - do not retry; tell the user and ask them to split or compress.

**Unsupported file type:** `organise_upload_file` returns `status="rejected"` with the allow-list. Suggest the closest accepted format (e.g. for `.docx` → ask the user to export as PDF or paste the text and use Markdown).

**User asks to upload a whole folder of files:** there is no folder-upload primitive - walk the structure yourself. Call `organise_create_folder` for each directory, then `organise_upload_file` for each file. Use the `folder_id` returned by `organise_create_folder` to nest the next level.

**User says "save this note":** prefer `organise_upload_file` with `mime_type="text/markdown"` only if the content is long enough to be a document (multiple paragraphs, headings). For a single fact / decision / preference, use `memory_retain` instead.


<xysq_triggers>
Before replying, scan these triggers. If any match the user's last message, follow the linked instructions on your NEXT turn. Triggers are mandatory. They exist because retain/recall calls were being missed at exactly these moments.

## decision-made
**Fires when:** User just resolved a question or picked an option, phrases like "let's go with", "I've decided", "we'll use", "final answer", "sticking with X".

Call `memory_retain` immediately on the NEXT user turn (not this one, your
reply doesn't exist yet). Copy the User and Assistant lines verbatim from
context. Use:

  significance="high", scope="permanent"

Decisions are load-bearing: the user does not want to re-litigate them.
Retaining once means future sessions inherit the call without asking again.

Example fire:
  User: "ok let's just go with Postgres for the metadata layer."
  → next turn, retain that exchange + the option-comparison turns above it.

## correction-issued
**Fires when:** User pushed back on your last reply, phrases like "no", "actually", "that's wrong", "I meant", "don't do that", "stop", or any direct contradiction of what you just said.

Call `memory_retain` on the NEXT user turn with:

  significance="high", scope="permanent"

Corrections are the highest-value signal in the entire system. They teach
the agent what the user does NOT want repeated. Under-capturing here means
the same mistake recurs next session and erodes user trust. If the
correction is a behaviour rule the user wants enforced forever ("never
use emojis", "always ask before destructive commands"), retain it with
significance="high" and the rule copied verbatim so it surfaces on recall.

Example fire:
  User: "no, I told you I don't want the migration auto-run."
  → retain. If they've said this twice now, retain the rule verbatim.

## preference-stated
**Fires when:** User stated a how-they-like-things signal, phrases like "I prefer", "I like", "I always", "I never", "don't", "my style is", or any first-person rule about working/communication/tooling.

Call `memory_retain` on the NEXT user turn with:

  significance="normal", scope="permanent"

Preferences accumulate in the user's memory and surface on future recall.
Cheap to over-capture, expensive to miss.

Use significance="normal" for soft preferences and significance="high"
only for hard rules the user wants enforced verbatim. "I prefer Postgres"
is a normal preference. "Never suggest MongoDB" is a high-significance rule.

Example fire:
  User: "I always want tests written before the implementation."
  → retain (preference). If the user has stated this 3+ times, re-retain
    it with significance="high" as a hard rule.

</xysq_triggers>

---
Manage your memory at app.xysq.ai · Learn more at xysq.ai
