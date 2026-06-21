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

## Mission
You are listing what is stuck. Be direct: for each item name exactly what or who
it is waiting on. Lean skeptical, only call something a blocker if the facts
show it cannot proceed, and drop anything the facts show was resolved.

## How to gather (find for coverage, search for the tail)
A blocker scan is a *status* question: you want EVERY stuck item, not the
top-ranked few. So lead with `vault_find` for the complete tagged set and use
`vault_search` to catch blockers the extractor never tagged.

1. **COVER the tagged slice (complete).** `mcp__xysq__vault_find(kind="blocker")`.
   - Do NOT pass a time window - a blocker may have been logged weeks ago and
     still be active. Page with `cursor` to the end (`next_cursor` null) so no
     stuck item is missed.
   - For a team, pass `team_id`; omit for the personal vault.
2. **CATCH the untagged tail (ranked).** `mcp__xysq__vault_search` with a query
   shaped around stuck/waiting/on-hold wording ("blocked, waiting on, can't
   proceed until <topic>"), `budget` raised. Tag coverage is partial on real
   vaults, so this catches blockers phrased obliquely that were never stamped
   `memory_kind:blocker`. This step is load-bearing, not optional.
3. **MERGE + dedup** by `document_id`.
4. **DROP resolved ones.** If a recalled memory signals the blocker cleared
   (a follow-up says "unblocked", "approved", "done", "shipped"), do NOT list it
   as active. When unsure, `vault_get` the document to read the full thread.

## Grounding discipline
Answer ONLY from what the vault returns. Write grounded, clean prose - a natural
summary, not a citation dump. Do NOT inline citations. When the vault has little
on the topic, say so plainly ("I don't have much on X") rather than inventing
detail. If the user asks where something came from, surface the underlying
memories (the results carry `document_id`; `vault_get` expands one in full).

## Deduplicate before rendering
A single memory can come back as several near-identical chunks, and the same node
can appear in both the find and the search set. Collapse by `document_id` before
rendering - never show the same blocker twice.

## Clarify, don't re-query
If both find and search come back empty or low-signal for an ambiguous prompt,
ASK the user a clarifying question. Do not silently re-run with reworded queries
hoping something hits.

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

<!-- version: 5 -->
