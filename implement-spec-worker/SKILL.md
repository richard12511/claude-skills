---
name: implement-spec-worker
description: Execute one coordinator-assigned phase for exactly one GitHub specification child ticket in its dedicated repository clone, preserving context across implementation, review fixes, no-mistakes gating, and recovery. Use only when an /implement-spec-loop or /implement-spec-overnight coordinator delegates an implement, fix-review, gate, or resume phase; do not use as a standalone replacement for /implement.
---

# Implement Spec Worker

Serve one coordinator and one child ticket. Never select a ticket, schedule reviewers, merge a PR, close an issue, recycle a clone, or start sibling work.

Require a coordinator assignment containing:

- phase: `implement`, `fix-review`, `gate`, or `resume`;
- parent and child issue numbers plus full current requirements;
- absolute dedicated clone path, branch, base SHA, and expected HEAD when applicable;
- run ID and coordinator identity;
- blockers and requirement hashes;
- exact review findings or gate decision when applicable;
- `resume_phase` when phase is `resume`;
- repository-specific policy overrides recorded by the coordinator, when any;
- complete user intent for no-mistakes.

If the assignment is incomplete or reconstructed Git/GitHub state disagrees, return `RECONCILIATION_REQUIRED` with the mismatch. This does not consume a retry or authorize `agent-stalled`. Do not guess or repair coordinator state.

## Common boundaries

- Work only in the assigned clone and ticket scope.
- Read all repository instructions before acting. Read the parent for intent, but never expand the child scope.
- Preserve user changes. Never reset, stash, overwrite, delete, or switch away from ambiguous work.
- Never spawn any subagent. All fan-out and every reviewer remain coordinator-owned. Questions go to the coordinator.
- Keep the branch name, clone path, base SHA, head SHA, tests, commits, PR, gate run, and unresolved items current in every handoff.
- Prefer `gpt-5.6-sol` with high reasoning for implementation and fixes. If the model is unavailable, continue on the nearest available frontier model and report the substitution.

## Phase: implement

1. Confirm the assigned clone has the exact origin, clean tree, checked-out fresh default branch at the coordinator's recorded base, and no unrelated active no-mistakes run.
2. Create the assigned `codex/issue-N-slug` feature branch from that exact base. Do not start from a cached or unverified branch.
3. Read the installed upstream `implement` skill completely at runtime. Follow its implementation, TDD, focused-testing, full-validation, and commit requirements, plus repository-mandated skills and checks.
4. Override only upstream `implement`'s final `/code-review` step: do not invoke it here. The coordinator owns phase-aware two-axis review scheduling.
5. Implement exactly the child acceptance criteria. Commit only ticket-owned changes.
6. Run all repository-required handoff checks, including build and smoke commands when mandated.
7. Return `READY_FOR_REVIEW` with the structured JSON handoff below, then become idle while preserving context.

If no durable progress exists by the first checkpoint, return a precise blocker and current fingerprint. Do not keep investigating without a receipt.

## Phase: fix-review

1. Require the same worker context when available. Verify the assigned branch and expected reviewed HEAD.
2. Read both aggregated review axes and fix every accepted correctness or error-level finding without expanding scope.
3. If findings conflict, are subjective, or change user intent, return `NEEDS_HUMAN` to the coordinator instead of choosing.
4. Re-run focused tests, repository-required build/smoke checks, and any affected full suite.
5. Commit the fixes on the same branch and return `REVIEW_FIX_COMPLETE` with the new HEAD.

Do not run reviewers yourself. The coordinator decides whether another review round is required.

## Phase: gate

1. Verify review approval applies to the current HEAD and all changes are committed.
2. Read the installed `no-mistakes` skill completely and follow its current AXI contract. Run home/status first and preserve the coordinator's full parent-and-child intent.
3. Never push directly and never use blanket `--yes`. In `richard12511/hordebound`, apply this only when the coordinator assignment records the user's standing skill-creation override of the repository's ordinary `--yes` shorthand. In every other repository, obey its shipping policy or return `RECONCILIATION_REQUIRED` for the coordinator to resolve.
4. While the gate is active, do not edit, hand-rebase, abort, or replace the branch. The pipeline owns it.
5. Resolve `auto-fix` and `no-op` gates within the no-mistakes contract.
6. For `ask-user`, leave the gate parked and return `GATE_DECISION_REQUIRED` with every finding's ID, file, and full description verbatim. Await a coordinator follow-up containing the human decision.
7. When a no-mistakes fix changes behavior and the pipeline presents a post-fix approval gate, keep it parked and return `GATE_DECISION_REQUIRED` so the coordinator can run read-only two-axis review. Apply any resulting accepted defect only through no-mistakes' supported `--add-finding`/fix response.
8. On `checks-passed`, return the PR URL, validated head, gate run ID, fixes table, and branch-sync state. Do not merge.
9. On terminal `failed` or `cancelled`, return `GATE_FAILED` or `GATE_CANCELLED` with the exact failure signature and custody state. Do not restart more than the coordinator authorizes.

Keep the live no-mistakes monitor running after `checks-passed`; it owns ordinary conflicts caused by earlier serial merges.

## Phase: resume

Require `resume_phase` naming the interrupted phase. Reconstruct from authoritative state before acting:

1. Git worktree, branch, local/remote HEAD, and commit history.
2. GitHub issue labels/comments, PR state/head/checks, and merge timestamp.
3. no-mistakes home/status, active run, gate, fixes, and `branch_sync`.
4. Coordinator ledger and expected assignment.

Return `RECONCILIATION_REQUIRED` instead of selecting the convenient version when state disagrees. When reconstruction agrees, return `RESUME_READY` with the authoritative phase, HEAD, PR, gate, custody, and exact next action, then continue only after the coordinator confirms or reissues that phase. Never infer a continuation phase from branch names alone.

## Questions and checkpoints

Send factual questions to the coordinator with evidence and a recommendation. Never address the user directly from a worker. Checkpoint before a time ceiling or interruption with all work committed when safe; if a commit is not safe, report the exact dirty paths without altering them.

## Handoff format

End every phase with exactly one fenced JSON object:

```json
{
  "status": "READY_FOR_REVIEW",
  "ticket": 553,
  "clone": "/absolute/path",
  "branch": "codex/issue-553-slug",
  "base_sha": "full-sha",
  "head_sha": "full-sha",
  "commits": ["full-sha"],
  "tests": [{"command": "dotnet test tests", "result": "passed"}],
  "pr": null,
  "gate_run": null,
  "branch_sync": null,
  "model_substitution": null,
  "unresolved": [],
  "question": null,
  "failure_fingerprint": null
}
```

Use only these status values: `READY_FOR_REVIEW`, `REVIEW_FIX_COMPLETE`, `GATE_DECISION_REQUIRED`, `CHECKS_PASSED`, `GATE_PASSED`, `GATE_FAILED`, `GATE_CANCELLED`, `RECONCILIATION_REQUIRED`, `RESUME_READY`, `NEEDS_HUMAN`, `STALLED`, or `CHECKPOINTED`.
