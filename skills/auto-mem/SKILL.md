---
name: auto-mem
description: "Activate recall-before-asking mode for the rest of this session: before stopping to ask the user a decision or preference question, the agent first queries xysq memory for a prior answer and acts on it if found. Fire when the user says 'auto-mem', 'recall before asking', 'use my memory for decisions', 'stop re-asking me things', 'check memory before asking', or signals they want past decisions to drive autonomous work silently. This is the forward-looking half of the memory loop (wrap-up saves; auto-mem recalls and acts)."
---

# auto-mem

## When this fires
The user wants the agent to stop re-asking questions they've already answered
somewhere in their xysq vault. Triggers: "auto-mem", "recall before asking",
"use my preferences for this", "don't ask me things I've already decided",
"check memory before stopping". Once activated it is STICKY for the session,
not a one-shot.

## Mission
Cut the "yes / yes / yes / approve" fatigue that builds when an agent keeps
asking the user questions they've already answered in past sessions. The
mechanism is simple: at every point where the agent would normally pause to ask
a decision or preference question, it first runs a targeted recall against the
user's xysq vault. If the vault has a clear prior answer, the agent acts on it
and tells the user in one line where it came from. If the vault is silent or
ambiguous, the agent asks normally. It never guesses, and it never improvises
from loosely-related patterns.

This is the forward-looking half of the memory loop. wrap-up (the
backward-looking half) saves durable decisions and preferences at the end of
a session. auto-mem drinks from what wrap-up deposited. Between the two, the
loop tightens: the user teaches once, the agent remembers.

## On activation: confirm clearly

When the user runs /auto-mem, respond with a single confirmation line. For example:

> "Recall-before-asking is on for this session. I'll query your xysq memory
> before each decision question. If I find a clear prior answer I'll act on it
> and tell you where it came from. If memory is silent, I'll ask you like normal.
> I won't guess."

That's all. Don't ask anything, don't start working. Wait for the user's next
instruction.

## How to use memory at each decision point

At every point where the agent would normally stop and ask the user a
decision/preference/approval question, run this loop instead:

1. **Formulate the targeted query.** Turn the specific choice into a concrete
   recall question: "what did I decide about <the exact choice>", or "do I have
   a standing preference for <the thing>". Keep it specific, not broad. A vague
   query returns noise and noise looks like signal.

2. **Run a targeted recall.**
   ```
   mcp__xysq__memory_recall(
     query="what did I decide about <the exact choice>",
     budget="low",         # "mid" for fuzzier or team-scoped decisions
     # for a standing preference ("what's true now"), add types=["observation"]
     # so a superseded older preference resolves to the latest one. Omit types
     # for a raw decision-history lookup.
   )
   ```
   Personal vault by default. Add `team_id` only when the decision is clearly
   team-scoped (e.g. an API convention owned by the whole team, not a personal
   style preference). Do NOT run both recall AND reflect for the same question;
   pick recall.

3. **Decision rule on the result.**
   - **Clear hit** (the result directly and unambiguously answers this choice):
     act on it. Tell the user in one short line what memory drove the call.
     Format: `(from memory: you decided X)`. Then continue working.
   - **Absent, low-signal, or ambiguous** (no result, or results that don't
     cleanly answer this specific choice): fall back to asking the user the
     normal question. Do not re-run recall with a reworded query hoping
     something hits. Do not improvise from loosely-related results.

   The bar for "clear hit" is high. If you have to squint at the result to make
   it fit the question, it doesn't fit. Ask.

4. **When acting from memory, surface which memory.**
   Always show the user WHAT was recalled and WHERE it came from (the
   `document_id` or a brief description of the source context). This lets the
   user catch stale or wrong memory immediately.

5. **When the user corrects a memory-driven default**, note the correction and
   point them at the retention path:
   > "Got it. You may want to run /wrap-up or use memory_retain to update that
   > preference so future sessions pick it up."
   Do not retain the correction yourself mid-session without asking. The user
   controls what goes into permanent memory.

## What auto-mem does NOT do

Be honest about this boundary. auto-mem reduces the QUESTIONS the agent asks by
answering them from memory. It does not:
- Flip Claude Code's permission mode (accept-edits, plan mode, yolo mode).
  That is a separate lever the user controls in settings.
- Auto-approve tool calls (file writes, shell commands, network calls).
  Those are gated by Claude Code's permission posture, not by this skill.
- Remove the need to ask for genuinely new decisions. If memory is silent,
  the agent asks. That's not a failure, that's the design.

The user who wants BOTH fewer questions AND fewer permission prompts needs to
set Claude Code's permission posture separately. auto-mem only handles the
memory half.

## Grounding discipline
Act ONLY from clear, directly-relevant recall hits. Do not:
- Infer an answer from a loosely related pattern.
- Stack multiple partial hits to construct an answer that no single hit supports.
- Treat a low-confidence or vague result as confirmation.

When in doubt, ask. A false positive (wrong memory driving the wrong call) is
worse than a question. The skill's value is precision, not coverage.

## Scope
Personal vault by default. Fan to a team vault (pass `team_id`) only when:
- The decision is explicitly a team convention (shared API style, shared tooling
  choice, etc.), AND
- The user has indicated team scope in their request.

Don't silently fan to team vaults for personal style questions.

## Output contract

On activation: one confirmation line as described above.

During session work, at each memory-driven decision:
- One short inline note: `(from memory: you decided X)` or
  `(from memory: standing preference for X, from <source context>)`.
- Then continue. Don't summarize the whole memory, don't editorialize.
  One line, then work.

When memory is silent: ask the question naturally, no preamble about having
checked memory (that would be noisy). Only mention the lookup if the user asks
why you're asking.

## Example

User runs /auto-mem, then asks: "add a delete endpoint for users".

The agent is about to ask "should I use a DELETE HTTP method or a POST
.../delete pattern?" It runs:

```
mcp__xysq__memory_recall(
  query="what HTTP method convention did I decide for delete operations",
  types=["observation"],   # a standing convention: return the resolved current fact
  budget="low",
)
```

The vault returns a clear hit from a past wrap-up session: "POST .../delete over
DELETE routes everywhere in this codebase."

The agent acts on it and says:

> "(from memory: you use POST .../delete, not DELETE routes, from session
> summary 2026-06-28)"
>
> Adding `POST /users/{id}/delete`.

Later in the same session, the agent needs to choose between two unfamiliar
logging libraries neither of which appears in the vault. Memory is silent.
The agent asks normally:

> "I don't have a prior preference on file logging. Do you want structlog or
> the stdlib logging module?"

That's the whole loop. Memory answered the first question; the agent asked the
second. No guessing in either case.

<!-- version: 2 -->
