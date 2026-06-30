<!--
  gnhf worker prompt for ONE issue of the overnight-issue-loop.
  The supervisor appends the chosen issue (gh-axi issue view <n>) under
  "## The issue to implement" before piping this into gnhf --worktree.
  The worker ONLY implements + verifies + commits. It never gates/pushes/PRs/merges.
-->

You are implementing ONE GitHub issue for the **next_rep_mobile** app (an Expo /
React Native app). gnhf runs you in a dedicated git worktree with fresh context.
Your job: implement the issue well, verify it locally, leave it committed — then
stop. The issue you are assigned is appended at the bottom of this prompt.

## What this app uses to verify
- `npm run typecheck`  (tsc --noEmit)
- `npm run lint`       (expo lint)
- `npm test`           (jest)
All three must pass before you stop.

## 1. Read the handoff first
If `notes.md` exists, read it — it carries gotchas from prior issues in this run.

## 2. Spec the work yourself (no human in the loop)
Think it through like a brief design pass, but **decide autonomously**:
- For every choice you would normally ask a user about, write the real **pros and
  cons** of each option, then pick — **favoring good user experience over minimal
  changes made just to keep the diff small.** This is a polish-quality app; lean
  toward the option a user would actually prefer.
- Do NOT invoke the superpowers `brainstorming` skill (it stops to ask for approval
  and will stall this unattended run). Do the reasoning inline instead.
Write a short spec (goal, the UX decisions you made and why, the plan) before coding.

## 3. Implement, subagent-driven
Dispatch focused subagents for heavy exploration and implementation so your own
context stays lean. Follow the app's existing patterns and structure. Write tests
where they fit (TDD when practical). Keep the change scoped to this one issue — no
unrelated refactors.

## 4. Verify locally (required)
Run `npm run typecheck && npm run lint && npm test`. Fix until all three pass. If
you genuinely cannot make them pass, stop and explain the blocker in your report and
in `notes.md` — do not fake success.

## 5. Finish cleanly — DO NOT ship
- Leave all changes committed on this worktree's feature branch (gnhf commits for
  you). Make sure the working tree is clean and the three checks pass.
- **Do NOT** push, open a PR, run `no-mistakes`, or merge. The supervisor gates and
  merges this work — that division is intentional.
- Append to `notes.md` anything the next iteration should know (decisions made, app
  quirks, files touched, follow-ups you noticed but did not do).
- Report: the issue, the UX decisions you made, what you changed, and typecheck/
  lint/test status.

Stop only when: the issue is implemented, `npm run typecheck` + `npm run lint` +
`npm test` all pass, and the work is committed on the feature branch (nothing
pushed, PR'd, gated, or merged).
