---
name: decisions
description: "Extract choices and calls made in a time window: what did we decide, what decisions were made last week, why did we pick X, what calls did I make, what was resolved. Pick this over recap when the focus is specifically on choices and rationale, not general progress. Pick this over blockers (which is about what is stuck, not what was decided)."
---

# decisions

## When this fires
The user wants an enumerated list of choices made in a window: "what did we
decide", "what decisions were made last week", "why did we pick X", "what calls
did I make", "what did we settle on", "what was agreed". Choose this over recap
when the focus is specifically on choices and their rationale - not a general
progress narrative.

## Mission
You are surfacing decisions the user made. Be precise and literal: report the
choice and its stated rationale, nothing inferred. If a decision has no clear
rationale in the facts, present it as "rationale unknown" rather than inventing
one.

## How to gather (find for coverage, search for the tail)
Decisions are a *complete-the-slice* question, so lead with `vault_find` (which
enumerates every matching node, server-side and unranked) and use `vault_search`
to catch decisions the extractor never tagged. Run both, merge, dedup.

1. **COVER the tagged slice (complete).** `mcp__xysq__vault_find(kind="decision")`.
   - For a window ("last week", "last month"), pass `time_start` and `time_end`
     as ISO bounds. This filters server-side and indexed - you do NOT over-fetch
     and post-filter by hand anymore. Resolve the relative phrase to concrete
     bounds (e.g. "last week" -> the Mon-Sun ISO range around today).
   - Page with the `cursor` until `next_cursor` is null if the user wants the
     full set; otherwise one page is usually enough.
   - For a team, pass `team_id`; omit it for the personal vault.
2. **CATCH the untagged tail (ranked).** `mcp__xysq__vault_search` with a
   decision-shaped query ("decisions and choices about <topic>"), `budget` raised
   for a window, and `query_timestamp` = today's ISO date. This surfaces
   decision-like memories that were never stamped `memory_kind:decision` (tag
   coverage is partial on real vaults, so this step is load-bearing, not
   optional). Post-filter these search hits to the window by `occurred_at`.
3. **MERGE + dedup** the two sets by `document_id`; a node from find and the same
   node from search is one item. Then keep only decision-shaped content.

For the current-position read (a superseded decision resolving to its latest
form), you can additionally `vault_search(..., types=["observation"])` - the
observation lane reconciles contradictions at synthesis time.

## Grounding discipline
Answer ONLY from what the vault returns. Write grounded, clean prose - a natural
summary, not a citation dump. Do NOT inline citations. When the vault has little
on the topic, say so plainly ("I don't have much on X") rather than inventing
detail. If the user asks where something came from, surface the underlying
memories (the results carry `document_id`; `vault_get` expands one in full).

## Deduplicate before rendering
A single memory can come back as several near-identical chunks (the engine
expands one memory into multiple entity-phrase variants), and the same node can
appear in both the find and the search set. Collapse by `document_id` before
rendering - never show the same decision twice.

## Clarify, don't re-query
If both find and search come back empty or low-signal for an ambiguous prompt,
ASK the user a clarifying question. Do not silently re-run with reworded queries
hoping something hits.

## Output contract
Return an enumerated list, most-recent-first. For each item:

- **Decision** - what was decided, in one sentence.
- **Why** - the stated rationale (omit if not logged).
- **Who** - who made or approved the call (omit if solo or unknown).

If the window yields no decisions, say "No decisions logged for <window>." and
offer to widen the window or check a specific topic.

## Example

User: "what did we decide about the event store last month"

Decisions (event store - last month):

1. **Decision** - Moving the event store to Kafka instead of Postgres.
   **Why** - Postgres could not keep up with the write throughput at peak.
   **Who** - Decided in the infra sync (Dana led).

2. **Decision** - Earlier call to use Postgres for the event store.
   **Why** - Simplicity and an existing operational footprint.
   **Who** - Solo call, later reversed by the Kafka decision above.

(Most recent first. The Postgres call is shown as superseded by the Kafka one.)

<!-- version: 5 -->
