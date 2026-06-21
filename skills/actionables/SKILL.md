---
name: actionables
description: "Surface open tasks, pending items, and stated priorities: what's pending, what do I need to do, what's been sitting too long, my open items, my priorities, what should I work on, what's on my plate. Pick this over recap (which covers the past) and over blockers (items STUCK waiting on someone external). This is forward-looking work the user owns."
---

# actionables

## When this fires
The user wants a forward-looking list of open tasks and priorities: "what's
pending", "what do I need to do", "what's been sitting too long", "my open
items", "my priorities", "what should I work on next", "what's on my plate".
Choose this over recap (past narrative) and over blockers (which is items that
cannot proceed - waiting on someone or something external).

## Mission
You are surfacing the user's open, self-owned work: the tasks they still need to
do. Forward-looking only; surface long-pending items prominently. Stay grounded.

## How to gather (find for coverage, search for the tail)
"What's on my plate" is a completeness question - the user wants the WHOLE list,
not the top-ranked few. Lead with `vault_find` for the complete tagged set and
use `vault_search` to catch tasks the extractor never tagged.

1. **COVER the tagged slice (complete).** `mcp__xysq__vault_find(kind="action")`.
   - Do NOT pass a time window - actionables can be old, and a long-pending item
     is exactly what the user wants surfaced. Page with `cursor` to the end
     (`next_cursor` null) so the picture is complete.
   - For a team, pass `team_id`; omit for the personal vault.
2. **CATCH the untagged tail (ranked).** `mcp__xysq__vault_search` with a query
   shaped around tasks and to-dos ("open tasks, need to, TODO, follow up on
   <topic>"), `budget` raised to over-fetch. Tag coverage is partial on real
   vaults, so this catches commitments phrased as plain statements that were
   never stamped `memory_kind:action`. Load-bearing, not optional.
3. **MERGE + dedup** by `document_id`, then drop anything with a done/completed
   signal so only still-open work remains. Sort oldest-unresolved first within
   the long-pending group.

## Grounding discipline
Answer ONLY from what the vault returns. Write grounded, clean prose - a natural
summary, not a citation dump. Do NOT inline citations. When the vault has little
on the topic, say so plainly ("I don't have much on X") rather than inventing
detail. If the user asks where something came from, surface the underlying
memories (the results carry `document_id`; `vault_get` expands one in full).

## Deduplicate before rendering
A single memory can come back as several near-identical chunks, and the same node
can appear in both the find and the search set. Collapse by `document_id` before
rendering - never show the same task twice.

## Clarify, don't re-query
If both find and search come back empty or low-signal for an ambiguous prompt,
ASK the user a clarifying question. Do not silently re-run with reworded queries
hoping something hits.

## Output contract
Return a prioritized list of open items. Group as:

1. **Long-pending** - items logged more than a week ago with no resolution signal.
2. **Active** - items logged recently and still open.
3. **Stated priorities** - anything the user explicitly flagged as high priority.

For each item: one-line description, date first logged, and any noted deadline or
priority signal.

If nothing is found, say "No open actionables logged." and offer to search by
topic.

## Example

User: "what's been sitting on my plate too long"

Open actionables (long-pending first):

- **Migrate the billing cron off the legacy queue** - logged ~4 weeks ago, no
  movement since. Oldest open item.
- **Update the SDK docs for the new token flow** - logged a few days ago.

These are tasks you own and can act on. For items stuck waiting on someone else,
ask for blockers instead.

<!-- version: 6 -->
