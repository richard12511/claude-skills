---
name: ship-and-close
description: End-to-end repository delivery that wraps the no-mistakes gate and completes post-merge bookkeeping. Use when the user invokes /ship-and-close or asks to ship or gate changes and then close every GitHub issue conclusively fixed by the merged PR and synchronize local main with remote main.
---

# Ship and Close

Ship committed feature-branch work through `no-mistakes`, preserve its human
merge boundary, and finish the work only after issue closure and local-main
synchronization.

## Follow the no-mistakes contract

Read and follow the installed `no-mistakes` skill before taking action. Treat
this skill as an extension of that workflow, never as permission to bypass,
duplicate, abort, or hand-edit around an active gate.

Preserve the user's complete intent when starting or reattaching the run. Use
`no-mistakes axi run --yes` only when the user has authorized unattended gate
decisions. Never use `git push` directly.

Before starting, inspect `git status`, the current branch, and
`no-mistakes axi`. The work must be committed on a feature branch. Preserve
unrelated changes and obey the repository's own branch-lifecycle rules.

## Record candidate issues before shipping

Build a candidate set from all available evidence:

- issue numbers explicitly named by the user;
- the branch name and commit subjects/bodies;
- issue references in the intended change, design documents, and tests;
- the eventual PR title and body.

Do not assume that every referenced issue is fixed. References such as
"blocked by", "follow-up", "related", "deferred", or historical context do
not establish completion.

## Drive the gate

Drive `no-mistakes` exactly as its skill instructs until it returns an outcome.
Process every gate response, acknowledge pipeline fixes, and respect its
`branch_sync` result.

When the outcome is `checks-passed`, report the PR URL and ask the user to
review and merge it. Stop there. Do not poll for the merge, merge the PR on the
user's behalf, close issues, or update local `main` yet.

When the user later confirms the merge, inspect or reattach the existing run as
directed by `no-mistakes axi` and its help output. Continue only after both are
true:

1. no-mistakes reports the successful terminal state for the run; and
2. the forge reports the PR as `MERGED` with a non-null merge timestamp.

A closed but unmerged PR is not success. Do not close issues for it.

## Audit every open issue against the merged PR

After merge, identify the final PR number and inspect its intent, complete diff,
commits, gate fixes, and merge result. Query the repository's complete current
open-issue list, not merely the PR's explicit closing references. Compare issue
titles and bodies with the behavior actually merged so unreferenced but fixed
issues are not missed.

Close an issue only when the evidence establishes all of the following:

- the issue describes behavior delivered by this PR, possibly completing work
  begun by an earlier merged PR;
- every substantive acceptance criterion in the issue is satisfied;
- the implementation is present on the default branch after the merge;
- the issue does not retain deferred work, an unresolved decision, required
  human evidence, or incomplete child tickets.

Leave an issue open when it is merely related, partially addressed, superseded
without an explicit disposition, a parent with unfinished children, or
ambiguous. Never use age, matching words, a branch number, or a PR mention by
itself as proof. Report uncertain candidates to the user instead of guessing.

For each issue that is still open and conclusively fixed, close it with
`gh issue close` and an evidence comment that links the merged PR and briefly
states what satisfied the issue. Skip issues GitHub already closed
automatically. Do not close pull requests while performing this audit.

## Synchronize local main

Read the gate's structured `branch_sync` state before changing branches. Apply
only the synchronization action authorized by `no-mistakes`; never improvise a
reset, rebase, stash, or branch replacement.

Once gate custody is resolved and the worktree is safe:

1. Check out the repository's default branch.
2. Run `git pull --ff-only origin <default-branch>`.
3. Verify the local and remote default-branch commits match.
4. Verify the worktree state and preserve any unrelated user changes.

Do not delete the feature branch unless the user separately requests cleanup.
If issue closure fails, still perform any safe authorized main synchronization,
then report exactly which bookkeeping step remains incomplete.

## Report the result

At `checks-passed`, report the merge-ready PR, validation summary, and any gate
fixes, then ask the user to merge.

After merge, report:

- the merged PR and terminal gate outcome;
- every issue closed, with links and the supporting reason;
- every plausible issue deliberately left open, with the missing criterion;
- the local default branch's synchronization result;
- any residual branch or worktree state the user should know about.

Do not call the workflow complete until the PR is merged, the issue audit has
run, and local main is synchronized, or until a specific blocker has been
reported.
