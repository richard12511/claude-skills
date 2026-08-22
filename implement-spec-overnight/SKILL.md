---
name: implement-spec-overnight
description: Run an entire Wayfinder-generated GitHub specification unattended through dependency-aware ticket workers, two-axis review, one no-mistakes-gated PR per ticket, automatic serial merges, issue closure, and resumable human escalations. Use when the user invokes /implement-spec-overnight or asks Claude to implement a multi-ticket GitHub spec overnight without routine interaction.
---

# Implement Spec Overnight

Run the installed `/implement-spec-loop` coordinator in `overnight` mode. This skill changes the judgment and stopping policy, not the core scheduler.

Before acting:

1. Read the installed `implement-spec-loop` skill completely.
2. Read every reference that skill marks as required, especially its full program protocol.
3. Read the installed `implement-spec-worker`, `implement-spec`, `implement`, `code-review`, and `no-mistakes` skills completely.
4. Apply all repository instructions and the complete parent/child GitHub specification.

If any dependency is unavailable, stop with the missing skill name. Do not improvise a simpler loop.

## Authority

Treat explicit invocation as standing authority to implement, gate, merge, close completed child issues, close a fully covered parent, maintain workflow labels/comments, create missing configured worker clones, synchronize local default branches, and create/delete only the shared protocol's exactly owned coordination lock ref. Preserve `manual merge` if the user supplies it. Never delete another ref.

This is not blanket consent for no-mistakes `--yes`, destructive actions, spending, licensing decisions, meaningful migrations, new product behavior, or subjective acceptance. Never use `--yes`; classify each gate finding by its actual action. In `richard12511/hordebound`, the shared coordinator records the user's standing skill-creation override of the repository's ordinary `--yes` shorthand. Do not infer or apply that exception in another repository.

## Overnight judgment boundary

Decide independently only when the answer follows from the specification, repository instructions, existing code and tests, dependency graph, or objective correctness.

Apply `needs-human` when a decision depends on any of:

- playtest feel, tuning preference, or visual/audio acceptance;
- choosing new product behavior not settled by the spec;
- conflict between the parent, child, and repository contract;
- a meaningful data/schema migration or compatibility tradeoff;
- spending, licensing, or external-account authority;
- destructive or hard-to-recover action;
- a no-mistakes `ask-user` finding that challenges user intent.

Do not approve, fix, or skip an `ask-user` finding on the user's behalf. Preserve the parked gate and copy its ID, file, and full description verbatim into the escalation.

For a human escalation:

1. Pause only that child and its descendants.
2. Preserve its worker context, clone lease, branch, commits, PR, gate run, and phase.
3. Add `needs-human`, remove `ready-for-agent` and active ownership as the shared protocol requires, and post the structured issue question.
4. Continue all independent frontier work.

The repository owner's first substantive issue reply after the escalation marker is the answer only when it unambiguously resolves the question or listed options. Do not clear `needs-human` for acknowledgements, follow-up questions, or ambiguous comments. On a later `/implement-spec-overnight`, `/implement-spec-loop`, or explicit `resume` invocation, record a valid answer, clear the blocker labels, and resume the preserved checkpoint.

## Stop instead of spinning

When every remaining child is `needs-human`, `agent-stalled`, or blocked by one of them:

1. Write a structured parent summary listing each decision, stall, blocked descendant, branch, PR, gate, and resume condition.
2. Invoke the shared protocol's fenced release with intended final status `paused`; follow its exact ledger, label, and conditional-ref order without adding any post-deletion write.
3. Leave every artifact recoverable and exit. Never keep polling for a human response.

Honor the shared 30-minute checkpoint, 3-hour ticket ceiling, 8-hour program ceiling, bounded retries, and unchanged-fingerprint rule. At the program ceiling, launch no new tickets; checkpoint active work and exit cleanly.

## Reporting

At the end of the unattended run, report:

- merged and closed tickets;
- tickets awaiting human answers, with direct issue links and exact questions;
- stalled tickets, fingerprints, and explicit retry commands;
- blocked descendants;
- active or preserved PRs and gates;
- clone lease and branch state;
- whether the parent closed and local `main` synchronized;
- review rounds, gate restarts, worker retries, model substitutions, and elapsed time.

Do not call a paused or partially blocked run complete.
