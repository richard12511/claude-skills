---
name: implement-spec-loop
description: Coordinate implementation of every dependency-linked child ticket under a GitHub parent specification, using isolated worker agents and repository clones, two-axis review, one no-mistakes-gated PR per ticket, automatic serial merges, issue closure, and local-main synchronization. Use when the user invokes /implement-spec-loop with a Wayfinder-generated GitHub spec or asks to run an entire multi-ticket spec interactively during the day instead of selecting only one ticket.
---

# Implement Spec Loop

Run one GitHub parent specification to completion as an interactive, resumable program. Act as the coordinator; never implement a child ticket in the coordinator clone.

Before acting, read [references/protocol.md](references/protocol.md) completely. Also read the installed `implement-spec`, `implement`, `code-review`, and `no-mistakes` skills completely. Their current contracts are dependencies; this skill overrides only the boundaries explicitly named below.

## Invocation contract

Accept a GitHub parent issue plus optional controls:

- `manual merge`: preserve a human merge boundary instead of the default automatic merge authority.
- `resume`: reconstruct and continue a paused or interrupted run.
- `takeover`: explicitly replace a stale coordinator lease after reconstruction proves this is safe.
- `--retry #N`: retry one `agent-stalled` child after relevant state changed.
- `--force-retry #N`: retry one stalled child even when its failure fingerprint is unchanged.
- `--pool-size N`: use `1` through `3` workers, capped by available agent slots; default `3`. Reject values above three in version 1.
- `--worker-clone PATH`: explicitly supply at most three worker clone paths for unusual layouts.

Reject local-only specifications in version 1. If the reference is a child ticket rather than a parent, recommend `/implement` for that child. If no generated children exist, recommend `/to-tickets`.

Invoking this skill grants standing authority to merge every qualifying ticket PR and close conclusively completed issues unless the user says `manual merge`. It also grants narrowly scoped authority to create and delete only the protocol-owned `refs/tags/codex-spec-program-lock-<parent-number>` coordination ref after exact ownership verification. It does not grant authority to delete any other ref or perform other destructive actions, spending, licensing decisions, migrations, subjective product choices, or acceptance that requires human playtesting or visual judgment.

## Coordinator role

Remain the control plane throughout the run:

1. Preflight GitHub state, the coordinator clone, the worker clone pool, no-mistakes availability, labels, and the parent lease.
2. Discover children and blockers, snapshot requirement hashes, reconstruct durable state, and calculate the ready frontier.
3. Lease at most one child to each clean worker clone and spawn a fresh `/implement-spec-worker` context for that ticket.
4. Schedule implementation, two-axis review, review fixes, no-mistakes gates, serial merges, closure, and clone recycling as separate phases.
5. Surface human questions immediately while continuing independent frontier work.
6. Update the parent ledger after every durable state transition.
7. Stop cleanly on completion, exhaustion, time ceiling, cancellation, or a fully blocked frontier. Never idle-poll.

The coordinator itself occupies one global agent slot. Never exceed three active subagents when four slots are available. Do not use the coordinator clone for ticket code or as a no-mistakes worktree.

Before acquiring the parent lease or mutating program state, require the coordinator clone to have a clean worktree, be on its default branch, fast-forward successfully from the exact `origin`, and equal the remote default-branch commit. Stop on any ambiguity; never stash or discard work automatically.

This pre-lease coordinator fast-forward is the sole permitted Git mutation before atomic lease acquisition; it exists to satisfy repository start-of-work freshness. Perform every worker-clone, branch, label, and ticket mutation only after acquiring the lease.

The user approved one Hordebound-specific branch-policy exception when creating this personal skill: in `richard12511/hordebound`, the serial lifecycle applies independently inside each full clone, so up to three separately leased clones may each own one ticket branch concurrently. Never stack branches within a clone. Do not infer this exception from invocation or apply it to another repository; obey that repository's instructions or stop as incompatible.

Prefer `gpt-5.6-sol` with high reasoning for the coordinator and every ticket implementer/fixer. When spawning a worker, request that model and effort explicitly when the host supports overrides. If the current coordinator model or requested worker model is unavailable, use the nearest available frontier model and record the substitution instead of aborting otherwise safe work.

## Daytime judgment policy

Answer worker questions only when the answer follows from the parent spec, child issue, repository instructions, existing code, tests, or objective correctness. For any product choice, playtest/visual acceptance, meaningful scope change, migration, spend, license, destructive action, or no-mistakes `ask-user` finding:

1. Pause only the affected ticket and its descendants.
2. Relay the exact question to the user immediately, with evidence, options, and a recommendation.
3. Continue unrelated ready tickets.
4. Record the user's answer on the child issue before resuming the preserved worker and clone.

Accept an answer in the Claude Code session or in the issue. When the answer arrives in the Claude Code session, mirror it to GitHub for durable traceability.

## Phase-aware scheduling

Use the protocol's scheduler exactly:

- **Implementation wave:** up to three ticket workers concurrently.
- **Review handoff:** a worker commits and returns `READY_FOR_REVIEW`, then becomes idle without losing context.
- **Review phase:** when two slots are free, spawn fresh Standards and Spec reviewers for exactly one ticket. Keep at most one other implementer or fixer active.
- **Fix phase:** aggregate findings without reranking the axes; reactivate the original ticket worker.
- **Gate wave:** after review clears, up to three workers may drive separate no-mistakes gates from separate clones.
- **Merge queue:** merge one eligible PR at a time. Leave every other no-mistakes CI monitor alive so it can repair conflicts caused by earlier merges.

Never run the upstream `implement` skill end-to-end inside parallel ticket workers: its final review would consume both remaining slots and collapse effective implementation concurrency. `/implement-spec-worker` reads and follows upstream implementation requirements but returns review scheduling to this coordinator.

## Two-axis review

At each `READY_FOR_REVIEW` handoff:

1. Pin the recorded base SHA and head SHA; require a non-empty three-dot diff.
2. Read the current installed `code-review` skill and follow its Standards and Spec prompts.
3. Spawn both reviewers together as fresh isolated agents.
4. Prefer `gpt-5.6-terra` with high reasoning for Standards and `gpt-5.6-sol` with medium reasoning for Spec. If unavailable, use the nearest available frontier model and record the substitution.
5. Aggregate reports side by side. Fix error-level findings and anything affecting correctness; a round containing only informational nits may pass under repository policy.
6. Reactivate the original worker for fixes, tests, and a new commit. Allow at most two review fix rounds per ticket.

If no-mistakes later makes a behavior-changing fix, repeat both axes before merge. At a post-fix approval gate, keep the gate parked, run the external reviewers read-only, and feed accepted defects back through no-mistakes' `--add-finding`/fix mechanism before approval. Mechanical fixes already re-reviewed by no-mistakes do not require another external review. If the pipeline reaches `checks-passed` without a gate where a discovered post-fix correctness defect can legally be submitted, do not edit, abort, or merge around the live monitor; mark the ticket `agent-stalled` with the exact custody state and require an explicit recovery decision.

## Gate and merge ownership

Load and follow the current installed `no-mistakes` skill in every worker gate phase. Preserve the full parent and child intent. Never push code directly. The coordinator protocol's atomic creation and conditional deletion of its exact coordination tag ref is the sole non-code ref exception; workers never perform it.

- Do not use blanket `--yes`; auto-resolve only `auto-fix` and `no-op` findings. Route every `ask-user` finding through the daytime policy.
- The user also approved one Hordebound-specific gate-policy exception when creating this personal skill: in `richard12511/hordebound`, use granular AXI responses instead of the repository's ordinary `--yes` shorthand so `ask-user` decisions retain their human boundary. Do not infer this exception from invocation or apply it to another repository. Preserve every other repository shipping requirement.
- While a gate is active, the pipeline owns the branch. Never edit, hand-rebase, abort, or replace it to bypass a gate.
- Treat `checks-passed` as merge eligibility, not completion. Confirm the PR head equals the validated head and all eligibility conditions in the protocol hold.
- The explicit loop invocation overrides no-mistakes' ordinary human-merge handoff. Merge serially using the repository's configured strategy, never `--admin`.
- After each merge, allow remaining live monitors to detect and repair conflicts. Do not duplicate their rebasing work.
- Verify a non-null GitHub `mergedAt` and no-mistakes terminal `passed` before closing the child, advancing descendants, or recycling its clone.

If `manual merge` was requested, stop each ready PR at `checks-passed`, report it, and resume only after the user confirms its merge. Preserve all other scheduler behavior.

## Completion

Close the parent automatically only when all are true:

- every discovered child is closed as completed;
- every ticket PR is merged;
- no child remains `needs-human` or `agent-stalled`;
- the final coverage audit maps every substantive parent requirement to completed child work;
- no requirement was lost through issue edits or dependency changes.

Post a parent summary linking every child and PR, close the parent, resolve no-mistakes branch custody, fast-forward the coordinator clone's default branch to its remote, and verify equality. Then sweep every configured non-quarantined worker clone: require a clean tree, switch to its default branch, fast-forward from the same remote, and verify equality. Include quarantined clones explicitly in the final report rather than mutating them. If child tickets are closed but coverage has a gap, keep the parent open and create a human escalation.

## Final report

Report completed and merged tickets, open escalations or stalls, clone and branch state, parent closure, local-main synchronization, review rounds, gate restarts, worker retries, elapsed time, and any model substitutions. Do not claim completion while any required bookkeeping remains.
