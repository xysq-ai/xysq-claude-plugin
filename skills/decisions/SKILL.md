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

## How to recall
Use `mcp__xysq__memory_recall` with `tags: ["memory_kind:decision"]`,
`types: ["observation"]`, and `personal_only: true` by default (so a superseded
decision resolves to the current one).

- Scope: default to the user's personal vault (`personal_only: true`). If the
  request names a team, pass that team's `team_id` instead; if it's genuinely
  ambiguous and permitted, omit `personal_only` to fan out across personal +
  recall-enabled teams and label each item by its `source`.
- Query: the user's stated topic or "decisions and choices" for the window.
- Set `query_timestamp` to today's ISO date for relative windows; post-filter
  by each row's `occurred_at` to stay inside the stated period.
- If the tag-filtered result is thin, re-run untagged recall with the same query
  and filter manually for decision-shaped content.

<!-- SHARED RECALL RECIPE - embed into each recall skill -->

## Grounding discipline
Answer ONLY from what recall returns. Write grounded, clean prose - a natural
summary, not a citation dump. Do NOT inline citations. When the vault has little
on the topic, say so plainly ("I don't have much on X") rather than inventing
detail. If the user asks where something came from, surface the underlying
memories (recall already returns them).

## Time-window handling
recall has NO server-side date filter. To honor "since yesterday / last
week / this month":
1. Put the relative phrase in the query text AND pass `query_timestamp` = today's
   ISO date so it resolves relative to now.
2. Over-fetch (raise `budget`) so the window's memories are surfaced.
3. Post-filter the results: keep only those whose `occurred_at` falls inside
   the target window.
Translate the user's phrase into both the query wording and the post-filter bounds.

## Tag-filtered recall
When a `memory_kind:*` tag keys this skill, pass it in `tags` to get the
pre-classified slice; fall back to untagged semantic recall if it yields too little.

## Deduplicate before rendering
Recall may return the same underlying fact as several near-identical chunks (the
engine expands one memory into multiple entity-phrase variants). Collapse these to
one item before rendering - never show the same fact twice.

## Clarify, don't re-query
If recall is empty or low-confidence for an ambiguous prompt, ASK the user a
clarifying question. Do not silently re-run recall with reworded queries hoping
something hits.

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

<!-- version: 4 -->
