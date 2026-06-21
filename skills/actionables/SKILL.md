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

## How to recall
Use `mcp__xysq__memory_recall` with `tags: ["memory_kind:action"]` and
`personal_only: true` by default.

- Scope: default to the user's personal vault (`personal_only: true`). If the
  request names a team, pass that team's `team_id` instead; if ambiguous and
  permitted, omit `personal_only` to fan out across personal + recall-enabled
  teams and label items by `source`.
- Query: the user's stated topic or "open tasks and priorities".
- Do NOT restrict by time window - actionables can be old. Pull broadly and
  surface long-pending items prominently (oldest unresolved first in that group).
- If the tag-filtered result is thin, fall back to untagged recall with a query
  shaped around tasks and to-dos.
- Raise `budget` to over-fetch since the user wants a complete picture of open
  work, not just recent items.

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

<!-- version: 5 -->
