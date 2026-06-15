---
name: blockers
description: "List what is stuck and what or who each item waits on: what am I blocked on, what's waiting on someone, what's stuck, what's holding things up, what's on hold. Pick this over actionables when the item CANNOT proceed - it is waiting on a person, approval, or external dependency. Pick this over recap (which is a past narrative, not a current status scan)."
---

# blockers

## When this fires
The user wants to know what cannot move forward right now: "what am I blocked
on", "what's waiting on someone", "what's stuck", "what's holding things up",
"what's waiting for approval", "what's on hold". Choose this over actionables
(which lists all open work the user owns) specifically when the item is stuck
waiting on an external dependency, person, or approval - not just unstarted.

## How to recall
Use `mcp__xysq__memory_reflect` with `tags: ["memory_kind:blocker"]` and
`personal_only: true`.

- Query: the user's stated topic or "blocked items waiting on external dependency".
- Do NOT restrict by time window - a blocker may have been logged weeks ago and
  still be active.
- If a recalled memory signals the blocker was resolved (e.g., a follow-up note
  says "unblocked", "approved", "done"), do NOT list it as active.
- If the tag-filtered result is thin, fall back to untagged reflect with a query
  shaped around "blocked", "waiting", "stuck", "on hold".

<!-- SHARED RECALL RECIPE - embed into each recall skill -->

## Grounding discipline
Answer ONLY from what recall returns. Write grounded, clean prose - a natural
summary, not a citation dump. Do NOT inline citations. When the vault has little
on the topic, say so plainly ("I don't have much on X") rather than inventing
detail. If the user asks where something came from, surface the underlying
memories (recall already returns them).

## Time-window handling
recall/reflect have NO server-side date filter. To honor "since yesterday / last
week / this month":
1. Put the relative phrase in the query text AND pass `query_timestamp` = today's
   ISO date so it resolves relative to now.
2. Over-fetch (raise `budget`) so the window's memories are surfaced.
3. Post-filter the results: keep only those whose `occurred_at` (recall) or
   citation `occurred_start` (reflect) falls inside the target window.
Translate the user's phrase into both the query wording and the post-filter bounds.

## Tag-filtered recall
When a `memory_kind:*` tag keys this skill, pass it in `tags` to get the
pre-classified slice; fall back to untagged semantic recall if it yields too little.

## Clarify, don't re-query
If recall is empty or low-confidence for an ambiguous prompt, ASK the user a
clarifying question. Do not silently re-run recall with reworded queries hoping
something hits.

## Output contract
Return a list of active blockers only (skip anything with a resolution signal).
For each:

- **Blocked item** - what cannot proceed.
- **Waiting on** - the person, approval, or dependency holding it up.
- **Since** - when the block was logged (if available).

If no active blockers are found, say "No active blockers logged." and offer to
check actionables for items that may be stalled without an explicit blocker tag.

## Example

User: "what am I blocked on for the release"

Active blockers:

- **Token change cannot ship** - **Waiting on** security review sign-off (Priya).
  **Since** ~2 days ago.

Note: a memory shows the security review later approved the token change, so that
blocker is resolved and is NOT listed above. Only still-blocked items appear here.

<!-- version: 1 -->
