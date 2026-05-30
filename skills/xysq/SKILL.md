---
name: xysq
description: >
  xysq is the persistent memory substrate for AI agents. With this skill
  active, Claude retains, recalls, and reasons over the user's decisions,
  preferences, project context, and prior conversations across sessions —
  so they never re-explain themselves.

  TRIGGER when:
  - User says "remember", "save", "note", "forget", "recall", "what did I
    say about", "what do you know about me / X".
  - User states a preference, makes a decision, corrects you, or shares a
    fact about themselves, their project, tools, or team — even in passing.
  - User mentions a project, codebase, person, or context by name Claude
    should already know — recall first, ask second.
  - First substantive message of any session — prime with memory_recall.
  - Problem is under-specified but references user/project context Claude
    lacks ("fix the auth bug", "draft a reply to my CEO") — recall once.
  - User pastes a URL, quote, code snippet, or chat transcript — use
    memory_retain with source:knowledge + source_type:* tags. For binary
    or long files (>10 KB), use organise_upload_file instead.

  SKIP when:
  - Pure greetings ("hi", "hey").
  - One-off coding questions with no personal/project signal ("syntax for
    async/await in Python").
  - Questions about xysq's own product or codebase, unless the user asks
    to store or recall something.

  Default operating mode whenever xysq is connected. Invoke generously —
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
  - mcp__xysq__knowledge_list
  - mcp__xysq__list_teams
  - mcp__xysq__organise_list_folders
  - mcp__xysq__organise_get_folder
  - mcp__xysq__organise_create_folder
  - mcp__xysq__organise_rename_folder
  - mcp__xysq__organise_move_folder
  - mcp__xysq__organise_delete_folder
  - mcp__xysq__organise_upload_file
---

## What changes when this skill is active

Every session without memory starts cold. The user re-explains their stack, restates their preferences, recaps last week's decisions. That re-explanation is the single largest waste in any AI workflow — measured in tokens, in time, and in the user's patience.

xysq is the substrate that ends that waste. The user has already consented to memory and given you the keys. Your job is to make that consent pay off: prime cold sessions with recall, recognize memory-worthy moments and retain them verbatim, and reason over prior context the way a colleague who has worked with this person for months would.

Treat this skill as the default operating mode, not a tool you reach for occasionally. Memory is a substrate, not a feature.

## How a memory-augmented session works

### On the user's first substantive message

Not greetings — wait for the first real ask. Then:

1. Call `memory_recall(query=<user's message, shaped as a lookup>, budget="high")` to pull relevant memories and wiki entries in parallel. Use the results as task-specific context before answering. Explicit user asks deserve the budget — quality over token-saving.
2. Call `authenticate()` lazily, on your first write (`memory_retain`, `memory_delete`) — not at session start.
3. Call `memory_tags()` just before your first `memory_retain`, not at session start. Invalid tags are silently dropped, so fetch the taxonomy only when you're about to use it.

Skip recall for: pure greetings, pure code-only questions with no personal signal, or follow-ups where the prior turn's recall already covered the ground.

When user profile context is pre-baked into an "About you" section of this skill, treat that as your working context for the entire session — no separate reflect needed to surface it.

### Proactive recall — the second-biggest leverage point

Reactive recall (user says "remember when") is easy. Proactive recall is what separates a memory-augmented Claude from a stateless one: noticing that a problem is under-specified and that memory probably contains the missing constraint.

**Recall proactively when both signals are present:**

1. **The problem references entities the user expects you to know** — a project name, a person, "my X", "our Y", "the Z we discussed". These are linguistic tells that the user has already mentally loaded the context and assumes you have too.
2. **The answer quality depends on personal/project specifics, not general knowledge.** "What's the syntax for async/await" → no recall. "How should I structure my async logic" → recall, because the right answer depends on the user's codebase, framework, and past decisions.

**Example — proactive recall pays off:**

> User: "help me fix the auth bug we hit yesterday"

Both signals present: "the auth bug" expects prior knowledge, and the fix depends on the user's stack. Call `memory_recall(query="auth bug yesterday", budget="mid")` before asking what stack they're on.

**Example — proactive recall is wasteful:**

> User: "what's the difference between Python's `is` and `==`?"

Neither signal present. General knowledge, no personal context. Answer directly.

**Anti-trigger — don't fish.** Recall is NOT a substitute for asking a clarifying question. If recall returns nothing relevant for an ambiguous prompt, ask the user — don't recall again with a different query hoping something hits. Fishing burns tokens without producing answers.

**Batch within a problem.** Recall once at the start of a problem, not repeatedly through the thread. If you already recalled in turn 1 of a 5-turn debug session, don't recall again on turn 3 unless the domain has shifted (coding → travel).

**Budget rule:**
- Explicit user ask ("what do you know about my project?") → `budget="high"`. The user is explicitly asking — pay for quality.
- Proactive recall (under-specified problem) → `budget="mid"`. Good signal-to-noise without being expensive.
- Reserve `budget="low"` only for follow-up recalls within an already-recalled thread.

### Recognizing memory-worthy moments — the implicit triggers

The user will rarely say "remember this." The high-leverage retains happen when you notice a memory-worthy moment in passing and capture it without being asked. Train yourself to recognize these patterns:

| Moment in conversation | What to retain |
|---|---|
| User makes a decision ("we're going with Postgres over MongoDB because…") | The decision + the reasoning, significance="high", scope="project" |
| User corrects your output ("no, I prefer integration tests over mocks") | The correction as a preference, significance="high", scope="permanent" |
| User states a preference in passing ("I always use Tailwind for styling") | Preference, significance="normal", scope="permanent" |
| User shares project context ("our deploy pipeline runs on Cloud Run") | Project fact, significance="normal", scope="project" |
| User shares a fact about themselves ("I'm the only backend engineer on this team") | Personal fact, significance="normal", scope="permanent" |
| User describes current task ("today I'm migrating from Firebase to Supabase") | Session context, significance="normal", scope="session" |
| User mentions a tool, library, or service they use regularly | Stack fact, significance="normal", scope="project" or permanent |

**Rule:** if in doubt, retain. Under-capturing costs the user more than over-capturing — every retained correction is a question they won't have to answer again next session.

### Explicit save commands

When the user says "remember this", "save that", "note this" — the save command is a **trigger, not the content**. Do NOT retain only the save command itself; retain the ENTIRE unsaved conversation so far. See the `memory_retain` reference below for the exact content format and `document_id` rules.

## Tool reference

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

---

### memory_recall — retrieve raw facts to reason over yourself
Use when you need source material to process yourself, not a pre-synthesised answer.

```
memory_recall(
  query,
  budget="mid",         # "low" | "mid" | "high" — see "Budget rule" above
  intent=None,          # "decision" | "preference" | "fact" | "context"
  scope=None,           # "session" | "project" | "permanent"
  domain=None,          # e.g. "tech", "health" — shorthand for tags=["domain:<value>"]
  mood=None,            # e.g. "focused", "frustrated" — shorthand for tags=["mood:<value>"]
  team_id=None,
)
```

Do NOT call memory_recall then memory_reflect for the same question. Pick one.

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

Call `memory_reflect` ONLY when the user's question itself requires synthesis across memory — "what do I prefer about X", "summarise my stance on Y", "compare my past decisions on Z". Not as warmup.

---

### Saving external sources — use memory_retain with source tags
When the user pastes a link, quote, code snippet, or chat transcript, save it
via `memory_retain` with the `source:knowledge` tag plus a `source_type:*` tag:

```
memory_retain(
  content="...",                                       # the URL, the quoted text, the code, the transcript
  tags=["source:knowledge", "source_type:link"],       # or quote / code / chat
  metadata={"url": "...", "title": "..."},             # type-specific fields go in metadata
  ...
)
```

Per source_type, put these in `metadata`:
- `link`:  `{"url": "...", "title": "..."}`
- `quote`: `{"title": "...", "location": "p. 47"}`
- `code`:  `{"language": "python", "location": "src/auth.py:12-40"}`
- `chat`:  `{"title": "..."}`

There is no separate `knowledge_add` tool — sources are just memories with
these tags. The xysq dashboard renders them as source cards in the Main view.

For binary files or long documents (>10 KB), use `organise_upload_file`
instead — it handles GCS storage and extraction.

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

---

## Organise — folders + uploaded files

The Organise tools let you save the user's documents (Markdown notes, PDFs, CSVs, images, JSON, plain text) into a folder tree the user can later browse at app.xysq.ai. Uploaded files are automatically extracted and indexed so their content surfaces through `memory_recall` and `memory_reflect` afterwards.

**Use `organise_upload_file` when:** the user hands you a document, pastes a long note, or asks you to save a file — anything they'd recognise as "a file" rather than a quick fact.

**Use `memory_retain` instead when:** the user is sharing a fact, decision, preference, or short note from the conversation. Memory is cheaper and more searchable for granular content.

**Use `memory_retain` with `source:knowledge` + `source_type:link` tags when:** the user pastes a URL or asks you to bookmark a link (see "Saving external sources" above).

### organise_list_folders — see the folder tree
```
organise_list_folders(team_id=None)
# Returns: { folders: [{ id, name, parent_id, path, is_system, chat_id }, ...] }
```
Call this before `organise_upload_file` if you need to pick the right destination folder. The vault root has `parent_id=None`; the system `/Chats/` folder has `is_system=true` and rejects direct uploads.

### organise_get_folder — inspect one folder
```
organise_get_folder(folder_id, team_id=None)
# Returns: { folder, children }  (children = subfolders, not files)
```

### organise_create_folder — make a new folder
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

### organise_delete_folder — ⚠️ irreversible
```
organise_delete_folder(folder_id, forget_memories=False, team_id=None)
# Returns: { deleted_assets: <int> }
```
Cascades: every subfolder + file under it is removed. Set `forget_memories=True` to also purge extracted facts from recall (default leaves memory content intact). **Confirm with the user before deleting any non-empty folder.**

### organise_upload_file — save a document
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

**Limits:** 10 MB per file; only the MIME types listed above are accepted. Filename collisions get a " (2)", " (3)", … suffix automatically — use the returned `filename` when echoing back to the user. After upload, `extraction_status` is `"processing"`; the file is immediately browsable in Organise but only enters recall once extraction completes. There is no folder-upload primitive — for a tree of files, walk the structure yourself with `organise_create_folder` + `organise_upload_file` calls.


## Consent and privacy

The user controls all stored data at app.xysq.ai and can review, edit, or delete at any time. Three rules:

- **No PII without explicit instruction.** Names, emails, addresses, IDs — don't retain unless the user explicitly asks. When they do, tag with `pii` or `confidential`.
- **Off the record means off the record.** If the user says "don't save that" or "this is off the record", do NOT call `memory_retain` for that exchange. If you already retained it, call `memory_delete` with the memory_id from the retain response.
- **Team vault access is gated.** A 403 means you're not authorised for that team_id — fall back to the personal vault (omit team_id). Do NOT retry with the same team_id.


## Edge cases

**Memory vault is empty (new user):** `memory_recall` returns few or no results. Proceed normally and start retaining from this session.

**memory_recall returns nothing relevant:** Proceed with the user's question directly. Do NOT fall back to a generic `memory_reflect` and do NOT recall again with a different query — absence of recall hits means there's nothing useful in memory for this query. Ask the user instead.

**memory_reflect returns confidence="low":** Treat the answer as a best-effort guess. Tell the user if they ask why you seem unfamiliar with their context.

**Tags are unknown:** Call `memory_tags()` just before retaining. Do NOT guess tag names — invalid tags are silently dropped without error.

**User pastes a URL or document:** Use `memory_retain` with `tags=["source:knowledge", "source_type:link"]` (or `quote`/`code`/`chat`) and put `url` / `title` / `location` in `metadata`. For binary or long files (>10 KB) use `organise_upload_file` instead. There is no separate `knowledge_add` tool.

**User asks "what do you remember about X?":** Use `memory_recall(query="X", budget="high")` and present the results. Do NOT use `memory_reflect` here — the user wants the raw list, not a synthesis.

**File over 10 MB:** `organise_upload_file` returns `status="rejected"` with a size message — do not retry; tell the user and ask them to split or compress.

**Unsupported file type:** `organise_upload_file` returns `status="rejected"` with the allow-list. Suggest the closest accepted format (e.g. for `.docx` → ask the user to export as PDF or paste the text and use Markdown).

**User asks to upload a whole folder of files:** there is no folder-upload primitive — walk the structure yourself. Call `organise_create_folder` for each directory, then `organise_upload_file` for each file. Use the `folder_id` returned by `organise_create_folder` to nest the next level.

**User says "save this note":** prefer `organise_upload_file` with `mime_type="text/markdown"` only if the content is long enough to be a document (multiple paragraphs, headings). For a single fact / decision / preference, use `memory_retain` instead.


---
Manage your memory at app.xysq.ai · Learn more at xysq.ai
