---
name: recap
description: "Synthesize what happened in a time window - catch me up, what did I work on, what happened this week, what's been going on, weekly recap, daily summary, what did I do yesterday. Fire even when the word recap is not used: any request for a period summary or progress narrative triggers this. Prefer this over decisions (choices only) or actionables (future tasks)."
---

# recap

## When this fires
The user wants a narrative summary of activity over a time window: "catch me up",
"what did I work on this week", "what happened in the auth project", "what's been
going on", "give me a weekly recap", "what did I do yesterday". Fire even when
the word "recap" is not used - the signal is a time-bounded progress narrative.

## How to recall
Use `mcp__xysq__memory_reflect` with `personal_only: true`.

- Default query: the user's stated topic or "recent activity" for the window.
- For "why" context, also reflect with `tags: ["memory_kind:decision"]`.
- For "what happened" detail, also reflect with `tags: ["memory_kind:event"]`.
- Set `query_timestamp` to today's ISO date and raise `budget` to over-fetch when
  a relative window ("this week", "yesterday") is given - then post-filter by
  `occurred_start` from results.

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
Return exactly four segments - tight and readable:

1. **What happened** - key events and milestones in the window.
2. **Why** - decisions or rationale behind the work (omit if nothing recalled).
3. **Who was involved** - collaborators or stakeholders (omit if solo or unknown).
4. **Suggested next step** - one concrete forward action based on what was logged.

If the window yields nothing, respond: "Nothing logged for <window>. Want me to
widen the window or search by topic instead?"

## Example

User: "catch me up on the auth work this week"

Recap (auth - this week):

**What happened**
Auth0 integration was wired up for the platform. The callback URL mismatch on port
5173 was identified and documented. The dual-auth spec (API key vs user identity)
was drafted.

**Why**
The team decided to support two auth modes - API key for anonymous agent use, and
user identity for cross-agent consent-gated memory. This keeps personal and org
scopes cleanly separated.

**Suggested next step**
Register port 5173 and 5176 in the Auth0 tenant so headless login can be tested
without a workaround.

<!-- version: 1 -->
