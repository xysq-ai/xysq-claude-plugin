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

## Mission
You are assembling context for an upcoming meeting or call. Pull broadly across
the topic regardless of age; favor recent but keep essential background. Neutral.

## How to gather (ranked search, by design)
Prep is topic-scoped and age-agnostic: you want the most RELEVANT context about a
topic regardless of when it was logged. That is exactly what ranked search is
for, so prep leads with `vault_search`, NOT `vault_find`. (Don't force this
through `vault_find` - a meeting brief isn't a "complete the tagged slice"
question, it's a "what's most relevant to this topic" question.)

Use `mcp__xysq__vault_search` with `personal_only: true` by default.

- Scope: default to the user's personal vault (`personal_only: true`). If the
  request names a team, pass that team's `team_id` instead; if ambiguous and
  permitted, omit `personal_only` to fan out across personal + recall-enabled
  teams and label items by `source`.
- Query: the topic, project name, or person the meeting concerns. Pull broadly -
  do NOT restrict by time window. Relevant context may be months old and still
  matters for a briefing.
- Favor recent results when ranking, but do not exclude older items that may
  provide essential background.
- Raise `budget` to pull a rich set of memories across the topic's history.
- If the topic names a person, also query with that person's name to surface
  relationship context, prior agreements, and open threads with them.

## Grounding discipline
Answer ONLY from what search returns. Write grounded, clean prose - a natural
summary, not a citation dump. Do NOT inline citations. When the vault has little
on the topic, say so plainly ("I don't have much on X") rather than inventing
detail. If the user asks where something came from, surface the underlying
memories (the results carry `document_id`; `vault_get` expands one in full).

## Optional: complete a specific slice
Prep is relevance-first, but if the user's topic has a clear structural angle
("every decision on the Acme deal", "all the blockers for this project"), you can
add one `vault_find(kind="decision"|"blocker", ...)` pass to guarantee that
slice is complete, then fold it into the briefing. Default is just `vault_search`;
reach for find only when completeness of a sub-slice clearly matters.

## Deduplicate before rendering
Search may return the same underlying fact as several near-identical chunks (the
engine expands one memory into multiple entity-phrase variants). Collapse by
`document_id` before rendering - never show the same fact twice.

## Clarify, don't re-query
If search is empty or low-confidence for an ambiguous prompt, ASK the user a
clarifying question. Do not silently re-run search with reworded queries hoping
something hits.

## Output contract
Return a structured briefing with four sections:

1. **Background** - what this topic or person is about, the core context.
2. **Recent activity** - what has happened lately that is relevant to the meeting.
3. **Open threads** - unresolved questions, pending decisions, or outstanding asks.
4. **Anything needing a decision** - items the user may need to resolve in this
   meeting, based on what is logged.

Omit sections that have no gathered content. If the vault has nothing on the
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

<!-- version: 5 -->
