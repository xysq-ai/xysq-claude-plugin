---
name: prep
description: "Assemble context for an upcoming meeting or call: I have a meeting about X what do I know, prep me for my call with Acme, what's the context for the topic sync, brief me before the standup, what should I know going into the design review. Pick this over recap (past window narrative) because prep is topic-scoped and forward-facing - pulls context regardless of age."
---

# prep

## When this fires
The user is about to enter a meeting, call, or sync and wants a briefing: "I
have a meeting about X - what do I know", "prep me for my call with Acme", "what's
the context for the auth sync", "brief me before the standup", "what should I
know going into the design review". This is forward prep - distinct from recap
(which is a past-window narrative). The anchor is a named topic, person, or event,
not a time window.

## How to recall
Use `mcp__xysq__memory_recall` with `personal_only: true`.

- Query: the topic, project name, or person the meeting concerns. Pull broadly -
  do NOT restrict by time window. Relevant context may be months old and still
  matters for a briefing.
- Favor recent results when ranking, but do not exclude older items that may
  provide essential background.
- Raise `budget` to pull a rich set of memories across the topic's history.
- If the topic names a person, also query with that person's name to surface
  relationship context, prior agreements, and open threads with them.

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
Return a structured briefing with four sections:

1. **Background** - what this topic or person is about, the core context.
2. **Recent activity** - what has happened lately that is relevant to the meeting.
3. **Open threads** - unresolved questions, pending decisions, or outstanding asks.
4. **Anything needing a decision** - items the user may need to resolve in this
   meeting, based on what is logged.

Omit sections that have no recalled content. If the vault has nothing on the
topic, say "I don't have anything logged on <topic>. Want me to search a related
term?"

## Example

User: "prep me for my 1:1 with Sam tomorrow"

Briefing for your 1:1 with Sam:

**Background**
Sam owns growth. You last synced with Sam and Dana on the Q3 roadmap.

**Recent activity**
The Q3 roadmap planning sync covered growth and infra ownership splits.

**Open threads**
No open growth items logged against Sam specifically.

**Anything needing a decision**
Confirm the growth slice of the Q3 roadmap if it was left open.

<!-- version: 1 -->
