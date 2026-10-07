---
name: implement-spec-loop-one-pr
description: Implement every dependency-linked child ticket under a GitHub parent specification on one integration branch, using parallel implementer agents in separate repository clones, one whole-spec two-axis review, and a single no-mistakes-gated PR for the entire spec. Use when the user invokes /implement-spec-loop-one-pr, or asks to run a spec as one PR instead of one gated PR per ticket. Experimental lean counterpart to /implement-spec-loop.
---

# Implement Spec Loop — One PR

Build the entire parent spec on one **integration branch**, review it once as a whole, gate it once through no-mistakes, and merge it as one PR. This is a deliberate experiment against `/implement-spec-loop`, which reviews and gates every ticket separately: it trades per-ticket verification for speed and token cost. Keep it lean, and record the comparison metrics below so the trade can be judged on evidence.

Act as the coordinator. Never implement a ticket in the coordinator clone.

Before acting, read the installed `implement-spec` skill (frontier and dependency rules), the `tdd`, `code-review`, and `no-mistakes` skills, and the repository instructions completely. Reject local-only specs. If the reference is a child ticket, recommend `/implement`; if no generated children exist, recommend `/to-tickets`.

## Invocation contract

Accept a GitHub parent issue plus optional controls:

- `manual merge`: stop at `checks-passed` and wait for the user to merge.
- `resume`: reconstruct and continue an interrupted run from its ledger.
- `--pool-size N`: `1` through `3` implementers; default `3`.

Invocation grants authority to create the integration and ticket branches, maintain workflow labels and the ledger, create missing clones, merge the single spec PR, close the parent and its children, and synchronize local default branches. It does not grant blanket no-mistakes `--yes`, destructive actions, spending, licensing, migrations, or subjective product and playtest acceptance.

**Hordebound policy exception**, approved by the user when creating this skill (2026-10-05) and limited to `richard12511/hordebound`: the integration branch is the program's single feature branch. Ticket branches are stacked on it, kept local, and never pushed or opened as PRs, which is the one sanctioned exception to the serial branch lifecycle's no-stacking rule. Use granular no-mistakes AXI responses instead of `--yes`, as `/implement-spec-loop` does. Do not apply either exception to another repository.

## Clones

Communicate between clones by **local path**, never through GitHub. Nothing is pushed until the final gate.

- **Coordinator clone** (the invoking clone): control plane only, stays on the default branch.
- **Integration clone**: `<base>_agent_integration`, where `<base>` is the invoking clone's path minus its final numeric suffix (`hordebound_2` → `hordebound_agent_integration`). It holds the integration branch and runs the final gate.
- **Implementer clones**: `<base>_agent_1` through `_agent_N`, one ticket each at a time.

Create a missing clone from the coordinator's exact `origin`. Before using any clone, require the matching origin, a clean tree and index, and no active no-mistakes run. Run `no-mistakes init` in a new clone if `no-mistakes status` reports it uninitialized. Quarantine a dirty or ambiguous clone and report it; never reset, stash, or delete it.

## Steps

1. **Preflight.** Fast-forward the coordinator clone's default branch from `origin` and require it to equal the remote. Refuse to start if the parent carries `agent-program-active` from another run. Apply that label, and create the label `agent-integrated` ("merged into the spec's integration branch; closes when the spec PR merges") if it is missing.

2. **Discover.** Find the children and blockers exactly as `implement-spec` does. Snapshot the parent and child bodies, then write the ledger (below).

3. **Integration branch.** In the integration clone, fast-forward the default branch, then create `codex/spec-<parent>-<slug>` from the coordinator's verified commit. Record that commit as `program_base_sha`.

4. **Explore.** Spawn one exploration agent, giving it pointers to the parent, the children, and the repository instructions. It writes markdown notes outside every clone to `~/.claude/spec-program-notes/<repo>-<parent>/`, with a `README.md` index mapping areas to tickets, and returns only the index path and a short summary. Skip this only for at most two children whose tickets already name their exact files.

5. **Implement the frontier.** A ticket is ready when it is open, carries no `needs-human`, and every blocker is closed or `agent-integrated`. Rank ties as `implement-spec` does. For each ready ticket, while a clone and an agent slot are free, apply `agent-in-progress` and spawn a fresh background implementer (Claude `opus`, high effort) with the assignment below. Keep at most three implementers active; the coordinator occupies the fourth slot.

6. **Integrate.** When an implementer returns `READY_TO_INTEGRATE`, verify its reported head with `git log`, then in the integration clone run `git fetch <implementer-clone> <ticket-branch>` and `git merge --no-ff`, naming the ticket in the merge message. Run the repository's build and unit-test commands in the background.
   - If the merge and checks are clean, record the merge SHA, swap `agent-in-progress` for `agent-integrated`, return the implementer clone to its default branch, and recalculate the frontier.
   - If the merge conflicts or the checks fail, abort only your own merge and spawn one **merger agent** in the integration clone with pointers to both branches and the failure. It resolves, re-runs the checks, and commits. It never rewrites integration history.

7. **Whole-spec review.** When every child is `agent-integrated`, pin `program_base_sha...<integration tip>`. Spawn the `code-review` Standards reviewer (Claude `opus`, high) and Spec reviewer (Claude `sonnet`, medium) together, with the **parent spec** as the source of intent. Aggregate their reports side by side.

8. **Fix once.** Route subjective, product, and scope findings to the user. Spawn a single fixer in the integration clone for every correctness and error-level finding. Every regression test must drive the production path and fail before the fix, and no fix may delete, weaken, or narrow an existing assertion to reach green. Repeat both rules in the fixer's instructions. Do not run a second review round; the gate is the second check. There is deliberately no per-ticket review and no seam audit; this experiment tests whether the whole-spec review catches what they would.

9. **Gate.** In the integration clone, load and follow the `no-mistakes` skill and run the gate on the integration branch. Its rebase step owns catching up with any default-branch commits that landed during the run.
   - Write `--intent` as a one-shot commitment covering the whole parent spec. It is immutable and quoted back on every review pass, so state each requirement as the exact property that must hold and reread it for over-literal readings before submitting.
   - Resolve `auto-fix` and `no-op` findings, and bring `ask-user` findings to the user verbatim with a recommendation.
   - Allow at most two complete gate restarts after terminal `failed` or `cancelled`; an identical failure signature stalls immediately.
   - While the gate runs, the pipeline owns the branch: never edit, rebase, or abort it to get around a finding.

10. **Merge and close.** At `checks-passed`, confirm the PR head equals the validated head and the PR is mergeable. Merge with the repository's configured strategy, never `--admin`, unless `manual merge` was requested. Verify a non-null `mergedAt` and a no-mistakes terminal `passed`. Then compare the merged diff against each child's acceptance criteria and the parent's requirements, and close each child and the parent with an evidence comment linking the PR. Remove the workflow labels. If a requirement is unmet, leave its issue open and report it.

11. **Clean up.** Fast-forward the default branch in the coordinator, integration, and implementer clones and verify each equals the remote. Delete the integration and ticket branches locally with safe `git branch -d` only, now that they are merged. Leave quarantined clones untouched and list them.

## Implementer assignment

Communicate through **context pointers**: issue numbers, the notes path, SHAs, and paths. Never paste issue bodies or the notes. Each implementer:

1. Verifies its clone is clean, fetches `<integration-clone> <integration-branch>`, and creates local `codex/spec-<parent>-issue-<N>-<slug>` from that exact tip.
2. Reads the ticket, the parent for intent, the notes index and the area files it maps to this ticket (orientation only; verify against the code), and the repository instructions.
3. Builds the ticket test-first with the `tdd` skill, within exactly the ticket's acceptance criteria, and commits.
4. Before reporting, fetches the current integration tip, merges it into its branch, resolves any conflicts, and runs the repository-required handoff checks.
5. Does not run `code-review`, push, open a PR, run no-mistakes, or spawn agents. It sends factual questions to the coordinator, and `NEEDS_HUMAN` for product decisions.
6. Ends with one fenced JSON object: `status` (`READY_TO_INTEGRATE`, `NEEDS_HUMAN`, or `BLOCKED`), `ticket`, `clone`, `branch`, `head_sha`, `integration_sha_merged`, `tests`, `question`, `unresolved`.

The coordinator answers questions only when the spec, tickets, repository instructions, code, or objective correctness settle them. For anything else, pause that ticket and its descendants, ask the user with evidence, options, and a recommendation, mirror the answer onto the issue, and continue independent tickets.

## Ledger and resume

Keep one edited parent comment marked `<!-- spec-program-one-pr-ledger:v1 -->`: a short human summary, then fenced JSON containing `run_id`, `skill`, `program_base_sha`, the integration clone, branch, and tip, the notes path, per-ticket `state` (`ready`, `implementing`, `integrated`, `needs-human`, `stalled`) with clone, branch, head, and merge SHA, the review counts, the fixer commit, the gate run and PR, and the metrics. Update it after every durable transition.

On `resume`, trust Git and GitHub over the ledger: rebuild ticket states from the integration branch's merge commits, the implementer clones' branches, the labels, and `no-mistakes axi status`, and report any disagreement before acting. Never idle-poll. Stop and report when the frontier is blocked only by human decisions.

## Comparison metrics

Record these in the ledger as they happen. At the end, append them as one JSON line to `~/.claude/spec-program-notes/runs.jsonl`, with `"skill": "implement-spec-loop-one-pr"`:

- the parent, the child count, and the diff size (files and lines changed);
- wall-clock timestamps for start, all integrated, review done, gate start, and merged;
- agents spawned by role, and total subagent tokens when the host reports them, otherwise `null`;
- whole-spec review findings by axis and severity, and how many were fixed;
- gate review rounds, findings by action, auto-fixes, restarts, and agent timeouts;
- merger interventions and human questions asked;
- escaped defects: leave this as `null`; the user fills it in after playtesting.

## Final report

Report the PR and its merge, the closed issues and any left open with the reason, the review and gate results, the metrics line, clone and branch state, and any model substitutions. Never call a run complete while the PR is unmerged or any bookkeeping remains.
