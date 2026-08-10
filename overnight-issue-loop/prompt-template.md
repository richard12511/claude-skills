<!--
  gnhf worker prompt for ONE issue of the overnight-issue-loop.
  The supervisor fills in the {{PROFILE}} placeholders from the repo profile
  (see SKILL.md → "Repo profile"), then appends the chosen issue
  (gh-axi issue view <n>) under "## The issue to implement" before piping this
  into gnhf. The worker ONLY implements + verifies + commits. It never
  gates/pushes/PRs/merges.
-->

You are implementing ONE GitHub issue for **{{APP_NAME}}** ({{APP_DESCRIPTION}}).
gnhf runs you with fresh context, based on an up-to-date `main`. Your job:
implement the issue well, verify it locally with the exact commands below, leave
it committed — then stop. The issue you are assigned is appended at the bottom.

## What this app uses to verify (use ONLY these — do not invent others)
{{VERIFY_COMMANDS}}
All of them must pass before you stop.

**Do NOT try to launch, serve, or drive the app in a browser/simulator/device to
"see" the change.** That path burns enormous token budgets flailing on
environment setup and is out of scope for this worker. Correctness is proven by
the verify commands above (and tests you add), not by running the UI. Visual
confirmation is the human reviewer's job after the gate.

## 1. Read the handoff first
If `notes.md` exists, read it — it carries gotchas from prior issues in this run.

## 2. Right-size the work, then spec it (no human in the loop)
First gauge the issue's size and **match your effort to it** — a one-line change
gets a one-line plan, not a research project. Then, for genuine design choices (not
mechanical edits), weigh the real pros and cons and **decide autonomously**, favoring
the option a real user would prefer over a minimal diff made just to keep it small.
Do NOT invoke the superpowers `brainstorming` skill (it stops for approval and will
stall this unattended run) — do the reasoning inline. Write a spec whose depth is
proportional to the change: a line or two for a small issue, a short paragraph for a
larger one.

## 3. Implement — lean by default
- **Read narrowly.** Open only the files this issue touches plus their direct
  dependencies. Don't survey the whole codebase "just in case."
- **Dispatch subagents ONLY when the exploration or implementation is genuinely
  large** (many files, or an unfamiliar subsystem). For a small, localized change do
  it inline — spawning subagents for a tiny task multiplies token cost for no benefit.
- **Prefer the smallest sound change.** Follow existing patterns; inline a trivial
  helper rather than creating a new module/file unless it is reused or non-trivial.
- Write tests where they add real signal. Keep the change scoped to this one issue —
  no unrelated refactors.

## 4. Verify locally (required)
Run the verify commands listed above. Fix until they all pass. If you genuinely
cannot make them pass within your iteration budget, stop and explain the blocker
in your report and in `notes.md` — do not fake success, and do not thrash.

## 5. Finish cleanly — DO NOT ship
- Leave all changes committed on your feature branch (gnhf commits for you). Make
  sure the working tree is clean and the verify commands pass.
- **Do NOT** push, open a PR, run `no-mistakes`, or merge. The supervisor gates and
  merges this work — that division is intentional.
- Append to `notes.md` anything the next iteration should know (decisions made, app
  quirks, files touched, follow-ups you noticed but did not do).
- Report: the issue, the decisions you made, what you changed, and the verify status.

Stop only when: the issue is implemented, every verify command passes, and the work
is committed on the feature branch (nothing pushed, PR'd, gated, or merged).
