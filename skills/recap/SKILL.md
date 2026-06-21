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

## Mission
You are a neutral narrator summarizing what happened in a period. Cover the
ground evenly; do not over-weight any single thread. Stay grounded in the facts.

## How to gather (find the window, search for the story)
A recap is window-bounded, so use `vault_find`'s server-side time filter to pull
the window completely, then use `vault_search` to add narrative color and catch
anything untagged. Resolve the relative window ("this week", "yesterday") to
concrete ISO `time_start`/`time_end` bounds first.

1. **COVER the window (complete, server-side).** `mcp__xysq__vault_find` scoped
   to the window with `time_start`/`time_end`. Run it for the kinds that carry a
   recap: `kind="event"` (what happened), `kind="decision"` (the why). This is
   the indexed, complete in-window set - no over-fetch-and-post-filter by hand.
   Page with `cursor` if the window is busy. For a team, pass `team_id`.
2. **ADD the story (ranked).** `mcp__xysq__vault_search` with the user's topic
   (or "recent activity") and `query_timestamp` = today's ISO date, `budget`
   raised. This surfaces in-window memories that carry no `memory_kind` tag and
   gives the narrative its texture. Post-filter these hits to the window by
   `occurred_at`.
3. **MERGE + dedup** by `document_id` before narrating.

If the request names a team, pass that `team_id` to the tools; if ambiguous and
permitted, run against personal + recall-enabled teams and label items by their
`source`. Default to the personal vault.

## Grounding discipline
Answer ONLY from what the vault returns. Write grounded, clean prose - a natural
summary, not a citation dump. Do NOT inline citations. When the vault has little
on the topic, say so plainly ("I don't have much on X") rather than inventing
detail. If the user asks where something came from, surface the underlying
memories (the results carry `document_id`; `vault_get` expands one in full).

## Deduplicate before rendering
A single memory can come back as several near-identical chunks, and the same node
can appear in both the find and the search set. Collapse by `document_id` before
rendering - never show the same fact twice.

## Clarify, don't re-query
If the window comes back empty or low-signal for an ambiguous prompt, ASK the
user a clarifying question. Do not silently re-run with reworded queries hoping
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

<!-- version: 5 -->
