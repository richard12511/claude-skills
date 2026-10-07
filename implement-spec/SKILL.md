---
name: implement-spec
description: Select and implement exactly one best ready ticket from a parent specification whose work has already been split into dependency-linked tickets. Use when the user invokes /implement-spec with a spec issue, plan, epic, or local ticket set and wants Claude to calculate the dependency frontier, choose the most useful unblocked ticket, and run the normal implementation workflow without treating the whole spec as one change.
---

# Implement Spec

Turn a parent spec into one safe implementation step. Discover its ticket set, calculate the open frontier, choose one ticket deterministically, and follow the installed `implement` skill with that ticket as the sole scope.

`implement` is user-invocable only. Never try to invoke it as a skill or slash command. Read its `SKILL.md` file directly — `~/.claude/skills/implement/SKILL.md`, or the equivalent path where skills are installed for this environment — and follow its contents as written.

## Non-negotiable scope

- Implement exactly one child ticket per invocation.
- Never implement the parent spec directly.
- Never combine sibling tickets because they touch related code.
- Never close, relabel, or rewrite the parent spec.
- Respect repository instructions, branch lifecycle, dirty-worktree ownership, and required skills.
- Keep discovery read-only. Begin tracker or code mutations only after selecting and announcing the ticket.

## 1. Resolve the parent

Read the full referenced spec body and comments. Resolve the configured tracker and repository instructions before selecting work.

If the reference is itself a generated child ticket with an explicit Parent section, stop and recommend `/implement` for that child. Do not silently reinterpret it as a parent.

## 2. Discover the ticket set

Find tickets belonging to the parent using this evidence order:

1. Native sub-issue or epic membership.
2. An explicit Parent field or section that references the parent.
3. The local ticket directory produced for that spec by `to-tickets`.

Do not include tickets that merely mention or link the parent in ordinary prose. Exclude the parent itself.

If no generated tickets exist, stop and recommend `/to-tickets` for the parent. Do not fall back to implementing the full spec.

## 3. Reconstruct dependencies

For every discovered ticket, read its current status and blockers.

- Prefer native blocking relationships when the tracker supports them.
- Otherwise use the ticket's explicit Blocked by field.
- Treat a ticket as ready only when it is open, carries `ready-for-agent` when that label vocabulary exists, and every blocker is complete.
- Treat missing, contradictory, or unresolvable blocker information as a planning defect. Report it instead of guessing.

Closed tickets count as complete. An open blocker outside the discovered set still blocks the ticket.

## 4. Choose the best frontier ticket

Build the frontier from all ready tickets. If it is empty:

- Report completion when every child ticket is complete.
- Otherwise report the open tickets and blockers preventing progress. Do not implement anything.

When more than one ticket is ready, rank candidates by:

1. Most unresolved downstream descendants unlocked by its completion.
2. Earliest tracker order, using the lowest issue or ticket number as the tie-breaker.

Use the ranking without asking the user to choose. Announce the selected ticket, its blockers, and why it outranked the other ready tickets.

Before implementation, confirm the repository is in a valid lifecycle state. Do not start a second feature branch when the repository requires the current branch to merge first.

## 5. Implement only the selection

Read the installed `implement` skill's `SKILL.md` completely and follow it with the selected child ticket as its complete scope. Do not attempt to invoke `implement` as a skill or slash command; it is user-invocable only. Also follow any repository-mandated design, TDD, validation, or review skills.

Pass the selected ticket's full body, comments, parent context, and blocker evidence into implementation. Parent context explains intent but does not expand scope.

If the `implement` skill file cannot be found or read, stop and report that dependency. Do not improvise a different shipping workflow.

## 6. Hand off

Report:

- The child ticket selected and why.
- What was implemented and verified.
- The ticket state and branch or commit produced by the `implement` workflow.
- Which tickets become frontier candidates next, while noting that repository branch rules may require merging first.

Do not automatically begin the next ticket.
