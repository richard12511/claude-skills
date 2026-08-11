---
name: refactor-file
description: Plan the breakup of an oversized source file into coherent responsibility modules. Maps the file, grounds in repo prior art, interviews the user, prototypes 2-3 competing refactors in parallel worktrees, has a reviewer agent critique them, hands all of it off side-by-side for the user to pick a winner, then files a tiny-commit refactor-plan GitHub issue. Use when the user wants to split, shrink, or refactor a large file, or invokes /refactor-file.
---

# Refactor File

The target file comes from ARGUMENTS (plus any context the user adds). The
deliverables are: (1) a user-chosen refactor direction, proven by real
prototypes, and (2) a filed GitHub issue containing a tiny-commit plan. This
skill plans and decides — it does **not** execute the refactor. The prototypes
are throwaways.

## Principles

These are hard-won (see any refactor-campaign retrospective the repo keeps —
Step 2 looks for one). Apply them throughout:

- **Start from measured maintenance pain, not a target architecture.** A large
  file is evidence of mixed responsibility, not automatic proof that new
  abstractions are needed. Deletion, inlining, and doing nothing are valid
  outcomes.
- **Never split by line count.** Each move must relocate one coherent
  responsibility *together with the state it owns*. Fields leave the host file
  with their methods; cross-responsibility coupling becomes explicit
  (constructor parameters), not ambient (shared fields).
- **Delete the replaced path in the same commit.** No compatibility layers
  that a "cleanup later" ticket is supposed to absorb.
- **No new ceremony.** An extraction should not mint new public
  protocols/concepts unless they replace more knowledge than they add. Beware
  the failure mode where a refactor *adds* thousands of net lines.
- **Measure success as: fields removed from the host, concepts a caller needs,
  and whether one representative future change touches fewer places** — not
  lines deleted.
- **Every rung must leave value if the ladder stops there.** Reassess after
  each rung; never auto-proceed to the next candidate.

## Step 1 — Map

Read the target file completely. Produce and show the user:

- a **responsibility-block table**: line ranges → the responsibility living
  there, in plain language;
- a **field census**: how many private/mutable fields, roughly partitioned by
  which responsibility owns them, and which fields are shared across blocks
  (those are the coupling hot spots);
- **churn evidence**: how many recent branches/PRs touched this file
  (`git log --oneline --since=... -- <file>` or the repo's history), to
  substantiate (or refute) "everything touches this file".

## Step 2 — Ground

Look for repo-local prior art before proposing anything:

- past refactor retrospectives or architecture audits (check `docs/`,
  `docs/reports/`, ADRs) — if one exists, its guardrails override this skill's
  defaults where they conflict;
- project instructions (CLAUDE.md, CONTRIBUTING) for conventions about where
  logic belongs;
- existing extraction patterns in the codebase worth copying (a coordinator,
  controller, or system class that already models the target shape).

## Step 3 — Interview

One question at a time, each with a recommendation. Cover, in order:

1. **The real pain**: findability, churn/merge pile-up, coupling fear
   (shared state + implicit ordering), or aesthetics? The answer decides
   which extractions make the cut.
2. **The mechanical shape** of an extracted block, chosen from the repo's
   established shapes (Step 2). Show small side-by-side code sketches if the
   user asks or seems unsure — especially when a framework concept (engine
   node vs plain object, etc.) is involved.
3. **The ladder**: propose an ordered list of extractions, easiest-first as a
   tracer bullet, riskiest once the pattern is proven. Name what explicitly
   stays in the host file.
4. **Prevention**: how the file is kept from regrowing. Default
   recommendation: a written rule in the project instructions ("this file is a
   composition root; new behavior goes in the owning module") as the ladder's
   final commit. Avoid line-count tripwires — they invite gaming.
5. **The verification bar** per rung: build + existing tests green + the
   project's fastest end-to-end check; rung-specific checks where machinery
   demands it; what the final full sweep and/or human check is.
6. **Branch mechanics**: default one PR per rung, serial.

## Step 4 — Prototype bake-off

Prototype 2–3 *genuinely different* refactors of the **first rung only** — not
the whole ladder. Different means structurally different (e.g. plain
coordinator class vs framework-lifecycle object vs recomposition), not three
flavors of the same idea.

- Create one isolated worktree per prototype. Use the environment's preferred
  worktree tool (per the user's global instructions — e.g. `treehouse`);
  only fall back to the Agent tool's built-in worktree isolation if no such
  tool is mandated.
- Spawn the prototype agents **in parallel**, one per worktree. Each agent's
  brief: implement the first rung fully in its assigned shape as one
  exploratory diff — real, compiling code, replaced path deleted, passing the
  project's build and the fast verification command from Step 3.5. Each agent
  reports: the diff, the host-file field/line delta, new public surface
  introduced, and any coupling it had to make explicit.
- Brief-writing traps learned in the field (hordebound rung 1, 2026-08-10):
  - When a shared data source (a generator, RNG, config value) is listed as
    *moving* but its call sites are listed as *staying*, the brief
    contradicts itself. Say which side owns the split — or explicitly permit
    folding call-site policy into intent-named methods on the new module
    (all three builders independently chose that; it was the right call).
  - Require builders to flag any RNG-stream, frame-ordering, or lifecycle
    divergence as an explicit behavior-preservation note, even "imperceptible"
    ones — those notes decided the ranking.
  - Ask builders to map where each dependency is *created* in the host's
    build sequence before choosing the construction site; construction-order
    traps (a collaborator built later than the module needs it) hit every
    shape.

## Step 5 — Agent review

Spawn one reviewer agent on the strongest available model. Its brief: evaluate
all prototypes against each other — pros/cons per variant, coupling each one
introduces or reveals, field/line/concept deltas, failure modes, and a worked
example of what one representative *future* change to this responsibility
would look like under each variant. The reviewer must also judge **ladder
fit**: whether each shape can be copied to the remaining rungs, or forces the
shape decision to be re-litigated later (in the field this criterion alone
eliminated an otherwise-strong variant). The reviewer ranks them and says
why. The reviewer's output is input to the user's decision, not a substitute
for it.

## Step 6 — Handoff and pick

Present everything side-by-side with the `lavish` skill (or a comparable
artifact if lavish is unavailable): per variant, the diff (or its essential
excerpts), the metrics from Step 4, and the reviewer's critique from Step 5,
plus the reviewer's ranking. The user picks the winner.

Then **discard all prototype worktrees, including the winner's**. The
prototypes are one big exploratory diff each; the real work will be
re-implemented as a reviewable tiny-commit ladder. The winning *design* is
what survives — save the winner's new-module file and full diff to the
scratchpad first, as the re-implementation reference. Note: pool worktrees
(treehouse) are *linked* worktrees, so prototype branches live in the host
repo's ref namespace — detach each worktree, then delete the branches from
the host repo, then return the worktrees.

## Step 7 — Plan and file

Turn the winning design into a plan of tiny commits — Fowler's rule: each
refactoring step as small as possible, so the program is always working. Each
commit names what moves, what gets deleted, and how it's verified. Structure
the plan as the ladder from Step 3.3: rungs → commits, a checkpoint after
each rung, the prevention rule as the final commit.

File it as a GitHub issue using this template:

```
## Problem Statement
The problem from the developer's perspective (use Step 1's measurements).

## Solution
The chosen direction and why (including what the bake-off decided, and what
deliberately stays in the host file).

## Commits
The LONG, detailed plan in plain English: rung by rung, commit by commit,
each leaving the codebase working. No file paths or code snippets that will
go stale — name responsibilities and behaviors instead.

## Decision Document
Implementation decisions made in the interview: shapes, ordering policy,
branch mechanics, prevention rule, success metrics.

## Testing Decisions
The verification bar per rung and at the end; what will NOT get new tests and
why; prior art for the checks used.

## Out of Scope
What this refactor will not touch.

## Further Notes (optional)
Guardrails, retrospective links, sequencing notes.
```

Execution of rung 1 happens in a fresh session on the user's say-so, not in
this one.
