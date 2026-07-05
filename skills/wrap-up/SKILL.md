---
name: wrap-up
description: "Summarize the current session and save it to xysq, losing no knowledge, just fewer tokens. Fire when the user says 'wrap up', 'summarize this session', 'save the session', 'save what we did', 'checkpoint this', 'store this session', or signals the session is ending and wants it persisted. This is the loop's persistence step: it extracts the durable knowledge from a long conversation into a compact, recallable memory so the next session (yours or a teammate's) starts informed instead of blank. Re-running in the same session UPDATES the same memory, it does not create a duplicate."
---

# wrap-up

## When this fires
The user wants the current session persisted to memory in compact form: "wrap
up", "summarize this session and save it", "save what we did", "checkpoint
this", "store this session". The intent is durable capture, not a chat reply.
Fire only on an explicit request, never unprompted.

## Mission
Compress the session for STORAGE, not for reading aloud. The contract is exact:
**lose no knowledge, just tokens.** A vague prose summary ("discussed auth, made
some decisions") is a FAILURE, it stores nothing recallable. You are extracting
the durable atoms a future session would need, and dropping only true filler.

Think of this as the INVERSE of `/compact`. Claude Code's `/compact` summarizes
for the model's working memory, so it keeps the conversation's shape and accepts
losing precision (exact numbers, code snippets, variable names, carefully worded
constraints are its first casualties). wrap-up wants the opposite trade: you may
drop the shape (the back-and-forth, resolved dead-ends, chatter), but you must
KEEP exactly the precision `/compact` throws away, because that precision is what
a future recall actually needs. Same instinct Anthropic's compaction encodes
(preserve state, next steps, learnings), tuned for durable recall instead of the
next turn.

What counts as filler you may drop: greetings, acknowledgements, thinking-out-
loud that led nowhere, dead-ends that were already resolved later in the session,
and verbatim chatter that names no fact, decision, person, file, or method. What
you must NEVER drop: any decision, fact, blocker, task, correction, preference,
or concrete detail (names, numbers, file paths, commands, error messages).

## How to summarize (structured extraction + a condensation catch-all)
Walk the whole session and pull the knowledge into buckets. Each bucket item is
one tight line, dense but complete (keep the WHY, the WHO, the exact value).

1. **Decisions** - every choice made, with its rationale. "Chose X over Y
   because Z." Tag the memory `memory_kind:decision`.
2. **Facts** - durable facts established about the project, code, people, or
   systems. "svc-A calls svc-B.postEntry on every capture." `memory_kind:fact`.
3. **Blockers** - anything stuck and what/who it waits on. `memory_kind:blocker`.
4. **Open tasks** - what's still to do, with any deadline. `memory_kind:action`.
5. **Corrections & preferences** - anything the user corrected you on or stated
   as a preference/instruction. Keep these close to verbatim, they are the
   highest-value, lowest-token memories. `memory_kind:decision` (high
   significance) or a `preference` framing. This includes how the user wants
   you to WORK: their approval cadence and autonomy preferences (e.g. "stop
   asking me to approve every step, act on my past decisions"), not just
   corrections to your output. These operating preferences are the
   highest-value memories for a future autonomous session; capture them
   verbatim. (The next session's /xysq skill recalls them so you start
   calibrated, not defaulting to maximum interruption.)
6. **Condensation catch-all** - anything important that doesn't fit a bucket
   above (context, partial progress, what was tried, what's in flight). Condense
   it to the fewest words that keep every concrete claim. This is the safety net
   so nothing of value falls through the buckets.

Then assemble ONE compact document from these buckets (sections in the order
above; omit a bucket if it's empty). This single document is what you retain.

Honesty check before saving: scan the session once more and ask "is there any
decision, fact, blocker, task, correction, or concrete detail I left out?" If
yes, add it. Compression that drops knowledge is the one thing this skill must
never do.

## How to save it (one document per session, re-run updates it)

This is the part that makes re-running safe. Mint ONE `document_id` for the
session the first time you wrap up, and REUSE it every time you wrap up again in
the same session, with `update_mode="replace"` so the session's memory is one
living document that stays current, never a stack of duplicates.

**First wrap-up of the session:**
```
memory_retain(
  content=<the assembled compact summary>,
  context="<client> session summary: <one-line topic>",
  tags=["memory_kind:decision", ...other memory_kind tags you used...],
  significance="high",
  scope="project",
  document_id=<omit on the very first call>,
)
```
The server returns a `document_id`. **Remember it for this session.**

**Every later wrap-up in the SAME session:**
```
memory_retain(
  content=<the freshly re-assembled summary, covering the whole session so far>,
  context="<client> session summary: <one-line topic>",
  tags=[...],
  significance="high",
  scope="project",
  document_id=<the SAME id the first wrap-up returned>,
  update_mode="replace",     # overwrite, not append: keeps it one current doc
)
```
Re-assemble the summary over the WHOLE session each time (not just the new part),
then `replace`. Result: one document that always reflects the latest state of the
session, no duplicates, no accumulation of stale copies.

If you genuinely cannot recover the earlier `document_id` (e.g. context was
compacted and you didn't note it), prefer to recall it first
(`memory_recall` for this session's summary) over minting a new one; only mint a
fresh id as a last resort, and say so.

## Scope: personal by default, team on request
- Default: personal vault (omit team_id). The summary is yours.
- If the user says "save this to the team" / "save to <team name>": call
  list_teams to get the id, then pass `team_id=<that id>` so the summary lands in
  the shared team vault. This is the move that turns your session into the team's
  starting context, your finest loop becomes everyone's.
- A team save still mirrors to your personal vault (tagged with the team), so you
  keep your own copy.

## Grounding discipline
Summarize ONLY what actually happened in the session. Do not infer, embellish, or
add knowledge that wasn't established. If the session was thin (little durable
content), say so and save a short honest summary rather than padding it.

## After saving, confirm briefly
Tell the user what you saved in one or two lines: the buckets captured and where
it went (personal or team), and that re-running will update this same memory.
Don't dump the full summary back at them unless they ask.

## Example

User: "wrap up and save this session"

(You walk the session and assemble:)

> **Session: payments rework, retry path**
> Decisions: chose exponential backoff for capture retries over fixed interval
> (peak load was dropping captures). Will add an idempotency key on
> ledger-svc.postEntry so retries are safe.
> Facts: payments-svc calls ledger-svc.postEntry on every successful capture;
> ledger-svc emits LedgerPosted, consumed by notify-svc for receipts.
> Blockers: notify-svc receipt template is hardcoded, waiting on design.
> Open tasks: implement the idempotency key; add the backoff to payments-svc.
> Corrections: user prefers POST .../delete over DELETE routes (API convention).
> Preferences: user wants me to act on prior decisions without re-asking (stop
> the yes/yes/yes approval loop), only pausing on genuinely new or irreversible
> calls.

(You retain that with significance=high, scope=project, a session document_id,
memory_kind tags, then confirm:)

"Saved a session summary to your personal vault: 2 decisions, 3 facts, 1 blocker,
2 open tasks, 1 preference. Run wrap-up again later and it'll update this same
memory instead of making a new one."

<!-- version: 2 -->
