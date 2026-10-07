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
3. Run shared exploration once per program and record the notes path.
4. Lease at most one child to each clean worker clone and spawn a fresh `/implement-spec-worker` context for that ticket.
5. Schedule implementation, two-axis review, review fixes, no-mistakes gates, serial merges, closure, and clone recycling as separate phases.
6. Surface human questions immediately while continuing independent frontier work.
7. Update the parent ledger after every durable state transition.
8. Run the whole-spec review after the last child merges.
9. Stop cleanly on completion, exhaustion, time ceiling, cancellation, or a fully blocked frontier. Never idle-poll.

The coordinator itself occupies one global agent slot. Never exceed three active subagents when four slots are available. Do not use the coordinator clone for ticket code or as a no-mistakes worktree.

Before acquiring the parent lease or mutating program state, require the coordinator clone to have a clean worktree, be on its default branch, fast-forward successfully from the exact `origin`, and equal the remote default-branch commit. Stop on any ambiguity; never stash or discard work automatically.

This pre-lease coordinator fast-forward is the sole permitted Git mutation before atomic lease acquisition; it exists to satisfy repository start-of-work freshness. Perform every worker-clone, branch, label, and ticket mutation only after acquiring the lease.

The user approved one Hordebound-specific branch-policy exception when creating this personal skill: in `richard12511/hordebound`, the serial lifecycle applies independently inside each full clone, so up to three separately leased clones may each own one ticket branch concurrently. Never stack branches within a clone. Do not infer this exception from invocation or apply it to another repository; obey that repository's instructions or stop as incompatible.

Prefer Claude `opus` with high reasoning for the coordinator and every ticket implementer/fixer. When spawning a worker, request that model and effort explicitly when the host supports overrides. If the current coordinator model or requested worker model is unavailable, use the nearest available frontier model and record the substitution instead of aborting otherwise safe work.

## Shared exploration notes

Before the first implementation wave, spawn one fresh **exploration agent** so implementers spend their context on implementation rather than each rediscovering the same code. Record the program's starting default-branch commit as `program_base_sha` in the ledger at the same time; the whole-spec review needs it.

1. Give it pointers, not copies: the parent issue, every child issue number, and the repository instruction files.
2. It surveys what the tickets will touch — the owning modules and files, existing peers to imitate, relevant tests and harnesses, domain terms, and any external documentation the tickets depend on — read-only.
3. It writes markdown notes **outside every clone** to `~/.claude/spec-program-notes/<repo>-<parent>/`, with a `README.md` index pointing to one file per area and naming which tickets each area serves. Record that path in the ledger as `exploration_notes`.
4. It returns only the index path and a one-paragraph summary. The coordinator never loads the notes wholesale.

Pass the notes path to every worker assignment as a context pointer. The notes describe `program_base_sha`; workers treat them as orientation and verify against current code, and the parent, child, and repository instructions always outrank them. Workers never write to the notes directory. When a later frontier ticket touches an area the index does not cover, the coordinator may spawn one supplemental explorer that adds a new file and index entry before that ticket starts.

On `resume`, reuse the recorded directory when it exists. Skip exploration only for a program with at most two children whose tickets already name the exact files to change; record the skip in the ledger.

## Daytime judgment policy

Answer worker questions only when the answer follows from the parent spec, child issue, repository instructions, existing code, tests, or objective correctness. For any product choice, playtest/visual acceptance, meaningful scope change, migration, spend, license, destructive action, or no-mistakes `ask-user` finding:

1. Pause only the affected ticket and its descendants.
2. Relay the exact question to the user immediately, with evidence, options, and a recommendation.
3. Continue unrelated ready tickets.
4. Record the user's answer on the child issue before resuming the preserved worker and clone.

Accept an answer in the Claude Code session or in the issue. When the answer arrives in the Claude Code session, mirror it to GitHub for durable traceability.

## Worker context budget

Prefer a **fresh worker context per phase** over one long-lived context per ticket. Spawn a new worker for `implement`, for each `fix-review`, and for `gate`, and let it inherit **durable artifacts** — the committed branch, the ledger entry, the aggregated review reports, the verbatim gate findings, and the recorded decisions — never a conversation transcript. The handoff schema already carries everything a successor needs; continuity of context is a convenience, not a requirement.

Reuse one context across phases only when the next phase genuinely depends on reasoning the worker has not written down, and prefer making it write that down instead.

Retire and respawn a worker when any of these hold:

- it exceeds roughly **250k tokens**;
- it has been resumed more than a few times;
- it is entering a phase that mostly executes rather than reasons — driving a parked gate, or running a revalidation command list.

A retiring worker checkpoints first: everything committed, the handoff JSON current, and any judgement worth keeping written into a code comment, the ticket, or the ledger. Record each retirement and its successor in the ledger. Retirement is not a retry and never consumes `worker_retries`; the same holds when a host loses a worker's transcript.

Treat a long-lived worker's later output with proportionate suspicion, and verify the cheap things rather than trusting them: reconstruct every SHA with `git log --format=%H` instead of accepting one from a handoff, and re-derive test, PR, and gate state from Git, GitHub, and `no-mistakes axi status`. Plausible-but-fabricated identifiers are a characteristic late-context failure.

Coordinator context obeys the same physics. Checkpoint the ledger whenever the coordinator's own context grows long, so the program survives a summarization boundary or a fresh `resume` without depending on anything held only in conversation.

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
4. Prefer Claude `opus` with high reasoning for Standards and Claude `sonnet` with medium reasoning for Spec — deliberately different models so the two axes do not share blind spots. If unavailable, use the nearest available frontier model and record the substitution.
5. Aggregate reports side by side. Fix error-level findings and anything affecting correctness; a round containing only informational nits may pass under repository policy.
6. Spawn a fix worker for fixes, tests, and a new commit, inheriting the aggregated reports rather than a transcript. Allow at most three review fix rounds per ticket.

Require every regression test to **drive the production path**. A test must reproduce the defect through the real call sequence — the actual coordinator, the actual event drain, the actual presentation — and must fail before the fix and pass after it. A test that stages the surrounding state by hand proves only that its assertion runs; it goes green while the shipped path stays broken, and is worse than no test because it reports a safety that does not exist.

Require also that **no fix deletes, weakens, or narrows an existing assertion in order to make a new one pass.** If an existing check appears wrong, the worker says so and leaves it failing: a failing test is information, a deleted test is the loss of it. Coverage removed to reach green is the most expensive kind of regression, because it destroys the evidence that would have caught the next one.

State both rules in every fix instruction rather than assuming them. They recur, they are invisible in a passing suite, and a green run is exactly the condition under which nobody looks.

## Seam audit before the gate

Two-axis review reads a diff and asks whether it is correct and faithful. It does not ask **what obligations this kind of change inherits**, so a ticket that introduces a new contract, coordinator, or cross-cutting seam can satisfy every stated criterion while silently failing to wire into systems no criterion names. Incremental review finds those one at a time, indefinitely.

Before gating a ticket that adds a Map/run contract, a new coordinator or system, or any boundary other subsystems must cooperate with, spawn one **fresh, narrowly-scoped auditor** whose only job is:

1. derive the obligation checklist from the existing peers of the thing being added — every boundary, lifecycle event, and hand-off they already handle, with the file and mechanism that implements each;
2. check the new work against that checklist;
3. state plainly whether what remains is a handful of gaps or a systematic problem, since that judgement decides whether the ticket merges after one batch or gets split.

Give the auditor the list of already-found defects so it spends its context on what nobody has checked. Require file, line, mechanism, and player-visible consequence for each gap, and require it to say which suspicions it checked and found genuinely handled — a short gap list is only credible when the reasoning behind it is visible. Fold accepted gaps into the live gate through no-mistakes' `--add-finding` rather than opening another review round.

Run this audit before the gate rather than after several fix rounds have already hinted at the pattern. Its cost is one context; the alternative is one gate round per missing obligation.

If no-mistakes later makes a behavior-changing fix, repeat both axes before merge. At a post-fix approval gate, keep the gate parked, run the external reviewers read-only, and feed accepted defects back through no-mistakes' `--add-finding`/fix mechanism before approval. Mechanical fixes already re-reviewed by no-mistakes do not require another external review. If the pipeline reaches `checks-passed` without a gate where a discovered post-fix correctness defect can legally be submitted, do not edit, abort, or merge around the live monitor; mark the ticket `agent-stalled` with the exact custody state and require an explicit recovery decision.

## Gate and merge ownership

Load and follow the current installed `no-mistakes` skill in every worker gate phase. Preserve the full parent and child intent. Never push code directly. The coordinator protocol's atomic creation and conditional deletion of its exact coordination tag ref is the sole non-code ref exception; workers never perform it.

- Do not use blanket `--yes`; auto-resolve only `auto-fix` and `no-op` findings. Route every `ask-user` finding through the daytime policy.
- Write `--intent` as a one-shot commitment, not a summary. It is **immutable for the life of the run** and is quoted back as the authoritative requirement on every review pass, so an imprecise sentence in it regenerates the same finding indefinitely and no amount of accurate `--instructions` removes the source — you end up arguing with a copy while the original still binds. State each requirement as the property that must hold, never a shorthand for it: "no visible run clock and no clock-bounded ending" rather than "no run clock at all". Reread it once for sentences a reviewer could take more literally than intended before submitting, because the only later remedies are absorbing one exchange per review cycle or discarding the run.
- The user also approved one Hordebound-specific gate-policy exception when creating this personal skill: in `richard12511/hordebound`, use granular AXI responses instead of the repository's ordinary `--yes` shorthand so `ask-user` decisions retain their human boundary. Do not infer this exception from invocation or apply it to another repository. Preserve every other repository shipping requirement.
- While a gate is active, the pipeline owns the branch. Never edit, hand-rebase, abort, or replace it to bypass a gate.
- Treat `checks-passed` as merge eligibility, not completion. Confirm the PR head equals the validated head and all eligibility conditions in the protocol hold.
- The explicit loop invocation overrides no-mistakes' ordinary human-merge handoff. Merge serially using the repository's configured strategy, never `--admin`.
- After each merge, allow remaining live monitors to detect and repair conflicts. Do not duplicate their rebasing work.
- Verify a non-null GitHub `mergedAt` and no-mistakes terminal `passed` before closing the child, advancing descendants, or recycling its clone.

If `manual merge` was requested, stop each ready PR at `checks-passed`, report it, and resume only after the user confirms its merge. Preserve all other scheduler behavior.

## Whole-spec review

Per-ticket review reads one diff at a time, so defects that live *between* tickets — a contract one ticket defines and another consumes differently, duplicated helpers, an obligation every ticket assumed someone else wired — pass every gate. After the last child merges and before parent closure, review the spec as one change:

1. Fast-forward the coordinator clone and pin `program_base_sha..<current default-branch head>`. If commits from outside this program landed in that range, list the program's merged PRs and merge commits for the reviewers and tell them that other changes are out of scope.
2. Read the current installed `code-review` skill and spawn its Standards and Spec reviewers together, as in two-axis review, with the **parent spec** as the Spec axis's source of intent. The Spec report doubles as evidence for the final coverage audit.
3. Triage the side-by-side reports:
   - correctness or error-level findings → one **integration-fix** worker in a clean worker clone, on a fresh `codex/spec-<parent>-integration-fixes` branch from current default, fixing every accepted finding in one batch, then gated, merged, and verified exactly like a ticket PR. Regression-test and no-weakened-assertion rules apply. Do not run another external review round unless the fix changes behavior beyond the findings.
   - subjective, product, or scope findings → the daytime policy, raised against the parent.
   - informational findings → list them in the parent summary; file issues only for those the user accepts as deferrals.
4. Record `final_review` in the ledger: the reviewed range, finding counts by severity, the fix PR, and what was deferred.

Run it once per program. Do not repeat it after the integration fix merges; that PR's own no-mistakes gate covers it.

## Completion

Close the parent automatically only when all are true:

- every discovered child is closed as completed;
- every ticket PR is merged;
- no child remains `needs-human` or `agent-stalled`;
- the whole-spec review ran, and its integration-fix PR, if any, merged;
- the final coverage audit maps every substantive parent requirement to completed child work;
- no requirement was lost through issue edits or dependency changes.

Post a parent summary linking every child and PR, close the parent, resolve no-mistakes branch custody, fast-forward the coordinator clone's default branch to its remote, and verify equality. Then sweep every configured non-quarantined worker clone: require a clean tree, switch to its default branch, fast-forward from the same remote, and verify equality. Include quarantined clones explicitly in the final report rather than mutating them. If child tickets are closed but coverage has a gap, keep the parent open and create a human escalation.

## Final report

Report completed and merged tickets, the whole-spec review's findings and integration-fix PR, open escalations or stalls, clone and branch state, parent closure, local-main synchronization, review rounds, gate restarts, worker retries, elapsed time, and any model substitutions. Do not claim completion while any required bookkeeping remains.

For comparison with `/implement-spec-loop-one-pr`, also append one JSON line to `~/.claude/spec-program-notes/runs.jsonl` with `"skill": "implement-spec-loop"` and the same fields that skill's **Comparison metrics** section lists. Here, review findings and gate data are summed across ticket rounds and the whole-spec review, and the timestamps are start, last child merged, whole-spec review done, and parent closed.
