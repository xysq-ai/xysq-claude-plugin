---
name: xysq-goal
description: "Bring ALL the context a goal needs into working memory by walking the vault like a codebase: search broad, enumerate complete, follow edges, read deep, stop when the goal is covered. Fire when the user hands you a goal that spans many memories/sources and one recall won't cover it: 'pull everything I know about the auth migration', 'what's the full picture on the Acme deal', 'gather all context for the payments rework across the codebases', 'brief me completely on X before I start'. Pick this over a single recall (one ranked query) and over recap/decisions/prep (single-shot micro skills) when COVERAGE matters more than a quick answer."
---

# xysq-goal

The macro skill. Where the micro skills (recap, decisions, blockers, prep) each
fire one ranked query, xysq-goal runs a goal-driven traversal: it keeps walking
the vault until the goal is covered, the way you'd walk a repo to understand a
feature. The knowledge graph is the map; this loop is you walking it toward a goal.

## When this fires
The user hands you a goal that no single recall can satisfy, because the context
is scattered across many memories and sources: "pull everything I know about the
auth migration", "what's the full picture on the Acme deal", "gather all context
for the payments rework, it touches three codebases", "brief me completely on X
before I start". The signal is COVERAGE over a goal, not a quick lookup. If one
recall would obviously answer it, use the regular recall tool, not this.

## The tools
You have three vault primitives. Know what each is FOR:

- `mcp__xysq__vault_search(query, budget, tags, ...)`, ranked, fuzzy. "Find
 memories ABOUT X." Your EXPLORE move. It ranks and drops low-scoring hits, so
 it's great for discovery, useless for "did I get everything."
- `mcp__xysq__vault_find(entity|source|tags|kind|document_id, time_start, time_end, cursor)`:
 COMPLETE, unranked, paged. "Give me EVERY node matching this filter." Your
 COVER move and your edge-walk (pass `entity=` to pull every node co-occurring
 with it). `next_cursor=null` means the filtered set is exhausted. This is the
 only tool that lets you TRUST you've seen everything in a slice. Two rules that
 bite if you forget them:
 - **At least one of entity/source/tags/kind/document_id is REQUIRED.**
 `time_start`/`time_end` are refinements, NOT selective filters: a call with
 ONLY a time range is rejected. Always pair time with one of the five.
 - **entity is best-effort, not guaranteed-complete.** It rides ranked recall
 under the hood, so for a heavily-mentioned entity the long tail can be
 dropped; the response then carries `partial: true`. Treat entity as a
 discovery/edge hop. When you truly need completeness, filter by
 source/tags/kind (those run on indexed columns and ARE complete).
- `mcp__xysq__vault_get(document_id)`, pull one node in full. Your READ-DEEP
 move, after search/find surfaces something worth expanding.

Rule of thumb: search to discover, find to cover, get to read deep. You will
interleave all three.

## The loop

The "frontier" is just a list you keep in your head/notes: one BRANCH per thing
worth exploring (a subgoal, an entity, a service), each with its current search
terms and a status of "active" or "exhausted". Seeding adds branches; expanding
walks one; a branch goes "exhausted" by the n+1 rule; the frontier is "dry" when
every branch is exhausted. Order doesn't matter, this is a traversal, not a
priority queue. Track per-branch status so you know when you're actually done.

```
GOAL = the user's problem statement.

1. DECOMPOSE the goal into 3-6 checkable subgoals. This IS your success
 condition, write them down explicitly. (e.g. for "context for the payments
 rework": understand each affected service, find the blocking decision,
 identify the owner, gather the acceptance criteria.) Vague goal in =
 vague coverage out, so make the subgoals concrete and checkable.

2. SEED the frontier: add one branch per subgoal. For each, one vault_search to
 get initial high-value nodes, plus a vault_find on any concrete filter the
 goal hands you (a source, a project tag, a kind). Mark each branch "active".

3. LOOP, bounded by a hard step cap (~20 tool calls) AND your token budget:
 a. EXPAND one branch (the n+1 controller, below):
 - COVER: vault_find scoped to the branch (entity=, source=, tags=,
 kind=, time range). Page with the cursor only as far as the
 subgoal needs, stop the moment it's covered, don't drain.
 - EXPLORE: vault_search on a rephrasing for anything find can't filter to.
 - WALK: vault_find(entity=X) on the high-value hits to follow edges
 (entity co-occurrence is the edge in v0).
 - READ: vault_get(document_id) on the few nodes that actually matter.
 - Keep hopping while each hop adds something NEW and relevant. When a hop
 comes back dry, do ONE MORE hop to confirm (a node can look dead while
 its neighbors-of-neighbors are gold). If that hop is also dry, the
 branch is done. [n+1 / loop-until-dry]
 b. When the FRONTIER goes dry (every branch exhausted by n+1):
 JUDGE coverage against your subgoals, which still lack a strong
 supporting node?
 - all covered (or step cap hit) -> STOP.
 - a subgoal is still uncovered -> RE-SEED: a fresh vault_search /
 vault_find aimed straight at the missing subgoal, then keep looping.
 (This is the recovery n+1 can't do on its own, see below.)

4. SYNTHESIZE: assemble the gathered context into your working memory, grouped
 BY SUBGOAL, each with its supporting nodes. Then answer the user's goal from
 that, grounded only in what you gathered.
```

## Why two stop layers (don't collapse them)
There are two different "when do I stop" questions. Conflating them makes the
loop either quit early or wander forever.

- **Is this BRANCH exhausted?** -> n+1 / loop-until-dry. Cheap, no judgment
 call, just "did the last pull add anything new." Does most of the bounding for
 free. The +1 confirmation hop guards against a node that looks dead but whose
 neighbors are valuable.
- **Is the GOAL satisfied?** -> subgoal coverage. Run this ONLY at dry-frontier,
 not every hop. n+1 tells you a branch is done; it says nothing about whether
 the goal is met. Classic miss: a goal touches svc-A..svc-D, but svc-D is never
 named in the goal, it matters only because svc-C calls it, and that edge is
 weak. n+1 declares every known branch dry and stops, having never discovered
 svc-D. Coverage catches it: svc-D's subgoal has no support -> re-seed a search
 for it -> n+1 walks the new branch. Dry frontier means "stop expanding what I
 have, now go find what I'm still missing", not "stop."

## Coverage check (do this honestly)
At dry-frontier, for each subgoal ask: do I have at least one strong, on-point
node supporting it? Be strict, a tangential hit is not coverage. If a subgoal
is thin, re-seed ONE targeted query for it and loop. If after a re-seed it's
still thin, mark it explicitly as "little/nothing in the vault on this" in the
output rather than padding. Don't grade your own homework generously; an honest
gap is more useful to the user than a confident blank.

**Re-seeding is the PRIMARY recovery path, not an exception.** In v0 edges are
coarse entity co-occurrence (and entity finds are best-effort, can be `partial`),
so n+1 routinely stops before the goal is fully covered, that's expected, not a
failure. The coverage check is what closes the gap, so EXPECT to re-seed for at
least one subgoal on a real goal, and don't read "dry frontier" as "done" until
the coverage check has actually confirmed every subgoal.

## Bounds (so a big vault can't turn this into a random walk)
- Hard step cap ~20 tool calls. If you hit it, stop and report what you covered
 and what you didn't.
- vault_find ALWAYS carries a selective filter, never a bare scan. Page only as
 far as the subgoal needs.
- Re-seed at most once per subgoal. Two dry re-seeds = the vault doesn't have it.

## Grounding discipline
Answer ONLY from what the vault returned. Group the synthesis by subgoal so the
user can see the shape of what you found. Do NOT inline citations as noise, but
if the user asks "where did this come from", surface the underlying nodes
(every result carries its document_id; vault_get expands it). When a subgoal
came up empty, say so plainly ("I found nothing in the vault on the rollback
plan"), never invent detail to fill a gap.

## Scope
Both vault_search and vault_find cover the same vaults by default: your personal
vault plus every team you have turned on for recall. So a goal that spans
personal and team knowledge is covered without extra work, search and find both
reach the teams, and find's `next_cursor=null` means every in-scope vault is
exhausted. Each result carries a `source` ("personal" or "team:<id>") so you can
tell where a node came from. To scope tighter, pass a single `team_id` (that team
only) or `personal_only=true` (your vault only) to the vault tools.

## Output contract
1. **Goal**, restate the goal and the subgoals you decomposed it into.
2. **What I gathered**, grouped by subgoal, the context found for each, in
 grounded prose. Mark any subgoal that came up thin.
3. **The picture**, a short synthesis tying the subgoals together into the
 answer the goal asked for.
4. **Gaps / next**, what the vault didn't cover, and the one concrete next step.

## Example

User: "pull together everything on the auth migration before I write the design doc"

**Goal:** Full context for the auth migration. Subgoals: (1) what's being
migrated from/to, (2) decisions already made, (3) what's blocking, (4) who owns it.

(loop: vault_search "auth migration" seeds 5 nodes; vault_find(kind=decision,
tags=["project:auth"]) covers the decisions completely; vault_find(entity="Auth0")
walks to the callback-URL nodes; one dry hop confirms; dry-frontier coverage
shows subgoal (3) thin -> re-seed vault_search "auth migration blocked waiting"
-> finds the tenant-config blocker; covered.)

**What I gathered**
- *From/to:* Moving off the legacy session-cookie auth to Auth0 with two modes
 (API key for agents, user identity for consent-gated cross-agent memory).
- *Decisions:* Dual-auth split was decided; personal and org scopes kept
 separate; ...
- *Blocking:* The headless login fails on a callback-URL mismatch until ports
 5173/5176 are registered in the Auth0 tenant.
- *Owner:* (thin, nothing in the vault names an owner.)

**The picture**
The migration is mid-flight: the model is decided and partly built, the one open
blocker is tenant config, and ownership isn't recorded.

**Gaps / next**
No owner on record and no rollback plan in the vault. Next: confirm who owns the
Auth0 tenant before the design doc assumes it.

<!-- version: 3 -->
