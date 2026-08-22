# Spec Program Protocol

Read this file completely before starting or resuming a program.

## Contents

1. Truth and discovery
2. GitHub labels and ledger
3. Coordinator lease
4. Worker clone pool
5. Frontier scheduler
6. Handoff schema
7. Review and gate budgets
8. Escalation and recovery
9. Merge and closure
10. Time and progress guards

## 1. Truth and discovery

GitHub, Git, the forge PR record, and no-mistakes are authoritative. The ledger is a checkpoint, never unquestioned truth. On every start or resume, reconstruct current state before trusting it.

Resolve the parent body and all comments. Discover children using this evidence order:

1. Native GitHub sub-issue membership.
2. An explicit `Parent` field or section that names the parent.
3. The parent's canonical generated-ticket checklist under a clearly labeled ticket/implementation section.

Do not include an issue merely because prose mentions or links the parent. Exclude the parent itself. Read every child's full body, comments, state, labels, native blockers, and explicit `Blocked by` section. Contradictory, missing, or unresolvable dependency data is a planning defect; do not guess.

A child is ready only when it is open, has `ready-for-agent` when that vocabulary exists, has no active ownership/escalation label, has no open PR or active gate, and every blocker—including blockers outside the child set—is complete.

Snapshot normalized parent and child issue-body hashes at program start, before review, and before merge. Ignore formatting-only edits. Treat material acceptance-criteria or dependency edits as follows:

- Daytime: show the diff and pause that ticket.
- Overnight: apply `needs-human` and write the exact diff summary.

Never merge code reviewed against materially older requirements.

## 2. GitHub labels and ledger

Ensure these labels exist; create them automatically with concise descriptions and distinct colors when absent:

| Label | Scope | Meaning |
|---|---|---|
| `agent-program-active` | parent | one coordinator currently holds the program lease |
| `agent-in-progress` | child | one worker and clone currently own the ticket |
| `needs-human` | child | product, acceptance, or authority decision required |
| `agent-stalled` | child | bounded automation retries exhausted |

On claim, add `agent-in-progress` and remove `ready-for-agent`. On human escalation or stall, remove `agent-in-progress` and `ready-for-agent`, then add the matching blocker label. On a recorded human answer, remove `needs-human` and restore `ready-for-agent`. On verified closure, remove transient labels. Remove `agent-program-active` whenever the coordinator ends, pauses, or completes.

Maintain one edited parent comment marked `<!-- spec-program-ledger:v1 -->`. Keep a short human summary followed by a fenced JSON object with at least:

```json
{
  "schema": 1,
  "parent": 550,
  "run_id": "spec-550-...",
  "mode": "daytime",
  "status": "active",
  "coordinator": "task-or-agent-id",
  "started_at": "ISO-8601",
  "heartbeat_at": "ISO-8601",
  "lock_ref": "refs/tags/codex-spec-program-lock-550",
  "lock_token": "unguessable-run-token",
  "lock_object_sha": "immutable-annotated-tag-object-sha",
  "lock_state": "held",
  "release_target": null,
  "release_nonce": null,
  "parent_hash": "sha256",
  "limits": {"pool": 3, "ticket_hours": 3, "program_hours": 8},
  "tickets": {
    "553": {
      "state": "implementing",
      "clone": "/absolute/path",
      "worker": "canonical-agent-id",
      "branch": "codex/issue-553-slug",
      "base_sha": "...",
      "head_sha": "...",
      "pr": null,
      "gate_run": null,
      "review_fix_rounds": 0,
      "gate_restarts": 0,
      "worker_retries": 0,
      "fingerprint": "sha256",
      "blockers": []
    }
  }
}
```

Update this single comment after every durable transition, before and after long-running gates, and when checkpointing. Avoid a stream of heartbeat comments.

## 3. Coordinator lease

Acquire the parent lease before mutating labels, worker clones, ticket branches, or code:

1. Perform read-only discovery plus the one allowed pre-lease mutation: cleanly fast-forward and verify the coordinator default branch as required by repository freshness policy.
2. Find the ledger marker, `agent-program-active` label, and dedicated lock ref `refs/tags/codex-spec-program-lock-<parent-number>`.
3. If the ref or an active lease belongs to another run, refuse to start.
4. Generate an unguessable run token. Create an immutable annotated tag object through the GitHub API whose message contains the run ID and token and whose target is the verified default-branch commit. Atomically create the exact dedicated lock ref pointing to that tag object. Ref creation must fail when the name already exists; never overwrite or force-update it. This exact coordination-ref operation is not code delivery and is the sole direct-ref exception to no-mistakes ownership.
5. Store the run token and immutable tag-object SHA in the ledger. Re-read the ref and require an exact target-SHA and token match. Only that winner may apply `agent-program-active`; every loser exits before ticket, label, worker-clone, or branch mutation.
6. A paused run has no lock: `resume` must atomically acquire a new tokened lock, then reconstruct every ticket before changing scheduler state. An interrupted run may retain its lock; `resume` may reuse it only when the tag-object SHA and token exactly match the ledger and no competing coordinator is live. Ambiguous liveness requires explicit `takeover`.
7. `takeover` is required to replace a stale or foreign lock. Refuse takeover when a live coordinator or incompatible mutation is observable. Post the exact old token/SHA and takeover evidence as a new immutable issue comment before acquisition; do not edit the canonical ledger yet. Delete the dedicated ref with a remote compare-and-delete operation equivalent to `git push --force-with-lease=<lock-ref>:<expected-tag-object-sha> origin :<lock-ref>`. If the target changed, deletion must fail; re-read state and refuse takeover. After successful deletion, acquire a new tokened lock. Only the successful new owner may update the canonical ledger. Never alter a code branch or unrelated tag.
8. Release with no writes after ref deletion. While the owned ref still fences successors, generate a release nonce and atomically edit the ledger to its final `status` (`paused` or `complete`), `lock_state: release-committed`, `release_target`, and nonce. Remove `agent-program-active`, then re-read both ledger and ref. Require the same run token, tag-object SHA, release nonce, and target. Conditionally delete the ref with the exact `--force-with-lease` expectation as the coordinator's last state mutation. Make no ledger, label, issue, or Git write after attempting deletion. If deletion fails because the target changed, do not retry blindly; the successor is fenced by its different token and the old coordinator must exit.

Recover a committed release before new work. When `lock_state` is `release-committed` and the ref still targets the ledger's exact tag-object SHA/token, an explicit `resume` or `takeover` may perform the same conditional deletion; neither the recoverer nor the original owner may write afterward. When the ref is absent, release is already complete and the final `release_target` is authoritative. A mismatched target is foreign ownership: do not delete it, require explicit `takeover`, and keep immutable evidence. A legacy or incomplete `releasing` state without a committed release nonce requires same-owner proof or explicit takeover before any transition. After a completed paused release, `resume` acquires a new tokened lock normally.

Never silently steal a lease based only on elapsed time.

## 4. Worker clone pool

The invoking clone is the control plane. Derive default worker paths by removing its final numeric clone suffix and appending `_agent_1` through `_agent_3` in the same parent directory. Example:

`hordebound_codex_2` → `hordebound_codex_agent_1..3`

Allow explicit paths and a smaller pool of one through three clones. Reject a pool size or explicit path set above three in version 1. Never exceed available subagent slots and never expand beyond the configured pool merely because the frontier is wide. Automatically clone a missing configured worker from the coordinator repository's exact `origin`.

Before leasing a clone, verify:

- its resolved `origin` matches the coordinator repository;
- its worktree and index are clean;
- it has no unrelated active no-mistakes gate;
- it has no unmerged or unpushed ticket ownership;
- its default branch can be checked out and fast-forwarded from remote;
- its local default branch then equals the remote commit.

Quarantine a dirty, ambiguous, divergent, or stranded clone. Never reset, stash, overwrite, or delete it speculatively. A quarantined configured clone may be replaced only through a new safe clone path; do not delete the original.

Lease exactly one ticket per clone. After verified merge and gate completion, honor no-mistakes `branch_sync`, confirm the tree is clean, switch to the default branch, fast-forward, verify equality, delete only the verified merged local ticket branch with safe deletion, and release the lease. Never delete worker clones automatically.

## 5. Frontier scheduler

Recalculate the graph only after a durable state event: claim, commit, review handoff, review outcome, gate transition, merge, closure, escalation, stall, requirement change, or user answer.

Build the ready frontier. Rank candidates by:

1. greatest number of unresolved downstream descendants unlocked;
2. lowest GitHub issue number as deterministic tie-breaker.

Lease up to the number of clean available clones and agent slots. Sequential dependencies wait for verified closure, not merely an open PR or `checks-passed` gate.

Never select a ticket carrying `agent-in-progress`, `needs-human`, or `agent-stalled`, or one with an open PR, active gate, unresolved blocker, or another run's claim. Block descendants of escalated or stalled tickets while continuing independent siblings.

## 6. Handoff schema

Require ticket workers to return a fenced JSON handoff:

```json
{
  "status": "READY_FOR_REVIEW",
  "ticket": 553,
  "clone": "/absolute/path",
  "branch": "codex/issue-553-slug",
  "base_sha": "...",
  "head_sha": "...",
  "commits": ["..."],
  "tests": [{"command": "...", "result": "passed"}],
  "pr": null,
  "gate_run": null,
  "unresolved": [],
  "question": null
}
```

Allowed statuses:

- `READY_FOR_REVIEW`
- `REVIEW_FIX_COMPLETE`
- `GATE_DECISION_REQUIRED`
- `CHECKS_PASSED`
- `GATE_PASSED`
- `GATE_FAILED`
- `GATE_CANCELLED`
- `RECONCILIATION_REQUIRED`
- `RESUME_READY`
- `NEEDS_HUMAN`
- `STALLED`
- `CHECKPOINTED`

Reject a handoff whose clone, branch, or HEAD disagrees with reconstructed Git state. Preserve the original worker's canonical agent identity so review fixes and gate continuation can reactivate the same context.

## 7. Review and gate budgets

Implementation contexts: one fresh context per ticket, plus at most one fresh retry after a no-progress failure. Maximum primary worker contexts: twice the child count.

External code review:

- exactly two fresh agents per review round: Standards and Spec;
- review only a pinned three-dot diff from recorded base to recorded head;
- maximum two fix rounds per ticket;
- informational-only nits may pass when repository policy allows;
- persistent correctness failures become `agent-stalled`;
- subjective acceptance failures become `needs-human`.

No-mistakes:

- do not cap the gate's internal review/fix rounds; it owns those limits;
- permit at most two complete gate restarts, counted only after terminal `failed` or `cancelled` outcomes;
- repeated identical terminal failure signatures stall immediately;
- while active, respond through AXI and never hand-edit the branch;
- preserve and act on structured `branch_sync` before any post-gate Git mutation.

Record every review fix round, gate restart, worker retry, and model substitution in the ledger.

## 8. Escalation and recovery

For `needs-human`, preserve clone, branch, commits, PR, parked gate, exact phase, and worker identity. Reserve the clone for that ticket unless the gate has safely released custody. Add the label and post a structured child comment containing:

- exact question or verbatim no-mistakes finding;
- current phase and why automation cannot decide;
- concrete options and tradeoffs;
- coordinator recommendation;
- supporting evidence;
- exact condition for resume;
- parent, run ID, branch, PR, and gate links.

The repository owner's first substantive issue reply after this marker is the durable answer only when it unambiguously resolves the stated question or options. Treat acknowledgements, follow-up questions, and ambiguous remarks as unresolved. A later daytime or overnight invocation records a valid answer in the ledger, removes `needs-human`, restores `ready-for-agent`, and resumes. An answer supplied in the Claude Code session must be copied to the issue.

For `agent-stalled`, post the repeated failure fingerprint, attempts, logs/evidence, preserved state, and recovery choices. Later runs must skip it until explicit `--retry #N`. A manually removed label does not authorize reselection: reconstruct the ledger and require the explicit retry control. Before retry, reconstruct the old fingerprint and require relevant state change. `--force-retry #N` explicitly overrides this comparison.

After an authorized retry, preserve the old fingerprint and stall cause in history, remove `agent-stalled`, and choose the transition by recorded phase. An implementation no-progress retry sets ledger state to `ready`, restores `ready-for-agent`, safely validates or releases the clone, and re-enters the ranked new-ticket frontier. A review retry keeps the preserved clone, adds `agent-in-progress`, leaves `ready-for-agent` absent, and enters the coordinator's review queue directly. A gate retry keeps the preserved clone and branch custody, adds `agent-in-progress`, leaves `ready-for-agent` absent, and enters the gate queue directly. Every path still honors dependencies, clone ownership, and global slot limits; review/gate recovery is not excluded merely because its own PR or gate already exists.

Keep retry budgets phase-specific. Only an implementation no-progress retry increments `worker_retries`, and that one permitted retry must use a fresh worker context. A review stall retains `review_fix_rounds`; retry re-runs the recorded review phase without silently granting another fix round. A terminal gate retry retains the original worker/custody and increments `gate_restarts` only when a new no-mistakes run actually starts. `--force-retry` bypasses an unchanged fingerprint, not any phase budget; exceeding a budget requires a separate explicit human decision.

When the run is interrupted, hits a ceiling, or has no runnable frontier, checkpoint all workers, invoke the section 3 two-phase release with intended final status `paused`, and exit with exact resume instructions only after release completes or its blocker is recorded. Do not bypass lock release, leave an inactive lease, or poll unchanged state.

## 9. Merge and closure

Before merging a ticket PR, require all of:

- exactly one assigned child and one PR for that child;
- every declared dependency is merged and closed;
- pinned two-axis review is clear;
- no required human acceptance remains;
- no `needs-human` or `agent-stalled` label;
- no-mistakes is stably `checks-passed` at the PR's current head;
- the PR is open, mergeable, and green under repository rules;
- all gate fixes are accounted for;
- any behavior-changing gate fix received external two-axis review.

Merge one PR at a time using the repository's normal enabled strategy. Never bypass protections or use admin merge. After each merge, leave other live CI monitors alone; they own ordinary conflict repair and will repush as needed.

Verify GitHub `mergedAt` and no-mistakes terminal `passed`. If the child remains open, close it only after comparing the final merged diff with every acceptance criterion; add an evidence comment linking the PR. Then recycle the clone and recalculate the frontier.

At program end, audit every parent requirement against the child set and merged diffs. Only a complete mapping permits the summary comment and parent closure.

## 10. Time and progress guards

Durable progress is one of: a failing behavior test that establishes the next executable step, a commit, review handoff, review decision, PR/gate transition, evidence-backed closure, or structured escalation. “Still investigating,” uncommitted diff growth, repeated checkpoints, and unchanged status checks are not progress.

- First worker checkpoint: 30 minutes. Require a test, meaningful diff, or precise blocker as evidence that the worker is not wedged; a meaningful uncommitted diff satisfies this checkpoint once but does not reset the ongoing durable-progress guard. A structured no-mistakes subprocess that is actively advancing is exempt.
- Per-ticket ceiling: 3 hours. Stop expanding scope and reach a recoverable checkpoint.
- Program ceiling: 8 hours. Stop launching tickets and checkpoint active work.
- No-progress rule: compute a fingerprint from issue state/labels, clone and branch HEAD, PR head/state, gate run/state, and blocker set. Two attempted transitions with the same fingerprint stall the ticket.
- Polling rule: use event-driven waits and bounded status checks around active subprocesses. Never create a tight or idle polling loop.

Revisit these conservative defaults only after roughly three successful programs provide evidence that a limit is counterproductive.
