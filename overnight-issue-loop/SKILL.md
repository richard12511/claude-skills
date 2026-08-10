---
name: overnight-issue-loop
description: Use when the user wants an unattended overnight loop that works through a repo's open GitHub issues one at a time — picking the highest-value issue, implementing it, gating it through no-mistakes, and merging — and asks to run, kick off, or resume the "overnight issue loop". Repo-agnostic: the host fills in a Repo Profile for the target repo (known profiles below include next_rep_mobile and throughline).
---

# Overnight Issue Loop

## Overview

An unattended loop that ships open GitHub issues one at a time. It is a **hybrid**
of two engines, split by who holds judgment:

- **gnhf implements** each issue in an isolated worktree with fresh context per
  issue (and `notes.md` handoff between issues). The worker writes a spec, codes it
  subagent-driven, and verifies locally — but it does **not** gate, push, PR, or merge.
- **The host agent (you) supervises the irreversible parts**: preflight the repo,
  hand the user the shimmed push that triggers the `no-mistakes` gate, monitor its
  outcome with judgment, then merge clean PRs to main and sync. (The gate trigger is
  currently a human step — see "Driving the gate".)

This split exists because the safety rail — **stop if anything looks iffy** — lives
at `no-mistakes`'s `ask-user` gate, which needs a human-escalable supervisor that a
headless worker can't be.

**REQUIRED BACKGROUND:**
- The **gnhf** engine — read the `gnhf` skill (`$(npm root -g)/gnhf/skills/gnhf/SKILL.md`). Run each issue in gnhf **Hands-Off** mode.
- The **no-mistakes** gate — read the `no-mistakes` skill. For this loop the host *drives* the gate agentically (see "Driving the gate").

The per-issue worker prompt is in [prompt-template.md](prompt-template.md).

## Repo profile (FILL THIS IN before running)

The loop is repo-agnostic. Before the first iteration, resolve a profile for the
target repo — either from "Known profiles" below or by inspecting the repo. Every
`{{PLACEHOLDER}}` in the worker prompt and the steps comes from here:

| Field | What it is |
| --- | --- |
| `REPO` | `owner/name` for `gh-axi` (the GitHub origin) |
| `LOCAL_PATH` | the primary local checkout path |
| `APP_NAME` | short app name for the worker prompt |
| `APP_DESCRIPTION` | one line, e.g. "an Expo / React Native app" or "a TS monorepo CLI + web inbox" |
| `VERIFY_COMMANDS` | the EXACT commands that prove correctness locally — **only what actually exists in the repo.** Do not assume `typecheck`/`lint`/`test`; check `package.json`. |
| `ELIGIBILITY` | which issues are in scope for this loop (and which to exclude) |
| `GATE_NOTES` | per-repo gate quirks (e.g. "gate runs on the primary checkout — free the worker branch to it first") |

### Known profiles

**next_rep_mobile**
- `REPO`: `richard12511/next_rep_mobile`
- `APP_DESCRIPTION`: an Expo / React Native app
- `VERIFY_COMMANDS`: `npm run typecheck` · `npm run lint` · `npm test`
- `ELIGIBILITY`: UI/UX issues only; exclude pure infra/backend (historically #4 EAS client, #6 API URL, #18 server cleanup)
- `GATE_NOTES`: gnhf worktree; standard gate

**throughline**
- `REPO`: `richard12511/throughline`
- `LOCAL_PATH`: `/Users/richardschmidt/Code/play/throughline`
- `APP_DESCRIPTION`: a TypeScript monorepo — a CLI (`packages/cli`) + core (`packages/core`) + a web "inbox" SPA (`packages/web`) that turns a GitHub PR into a guided walkthrough
- `VERIFY_COMMANDS`: `npm run build` (tsc across all workspaces) · `npm test` (vitest). **There is NO `lint` and NO `typecheck` script — do not invent them; `build` is the type-check.**
- `ELIGIBILITY`: self-contained, single-surface issues (bug fixes and small UI/UX affordances). Exclude exploratory/epic issues (e.g. #16 execution-sequence overlay, #33 inline agent chat) and anything needing infra the app lacks.
- `GATE_NOTES`: the no-mistakes gate operates on the **primary checkout** (`LOCAL_PATH`). Before gating, the worker's branch must be checked out **there**, not held by a linked worktree. Also: this clone maps to no-mistakes repo hash `d32da9283a5f`; the sibling clone `throughline_2` maps to a *different* hash, so their gate slots are independent.

## The rails (don't violate)

1. **Cap: N issues per run** (default 3; for a first supervised run, **1**). Stop early
   if no eligible issue remains or the gate keeps failing.
2. **Eligibility per profile.** Only pick issues the profile marks in scope.
3. **Merge only on a clean gate.** A `no-mistakes` outcome of `passed`/`checks-passed`
   with a sane diff → merge. Anything else → don't merge.
4. **Stop-if-iffy = skip that issue and continue.** If an `ask-user` finding or the
   diff looks off, do NOT merge: leave the PR/branch, write a note, move to the next
   issue. (In a 1-issue supervised run, "iffy" means **stop and report**, per the
   caller's instruction.)
5. **The worker never gates, pushes, PRs, or merges** — that's the supervisor's job.
6. **Pause for user approval after each issue.** Default mode: at the end of every
   issue (merged or skipped), stop and report; do NOT start the next issue until the
   user says go. Only run fully back-to-back if the user explicitly asks for it.

## Token safety (the reason a prior QA loop burned ~8M tokens for 0 commits)

The failure mode is a worker **spinning to get code running** on iteration 1 —
never reaching a commit. Guard against it every run:

1. **Preflight the baseline yourself first.** Sync the primary checkout to fresh
   `origin/main`, then run the profile's `VERIFY_COMMANDS` (plus `npm install`).
   Confirm they pass **before** spawning any worker. If the toolchain is broken on
   `main`, stop and tell the user — do not send a worker into a broken baseline.
2. **Verify = the profile's commands ONLY.** The worker prompt forbids launching/
   browser-driving the app to "see" the change. That browser-driving spiral is what
   burned the tokens.
3. **Low iteration cap + active monitoring.** `--max-iterations 6` for a first run.
   Watch the background run; if it makes no diff progress or loops on the same
   failure, **kill it** (`TaskStop` / kill the background process).
4. **Bounded everything, then stop.** If any step (worker, gate) can't make progress
   in a few bounded attempts, **stop and file a GitHub issue** describing what failed
   and why — never spin.

## The loop (host agent runs this)

Repeat until the cap is hit, or no eligible issue remains:

1. **Pick the issue.** List open issues and read candidates:
   ```sh
   gh-axi issue list -R <REPO> --state open --limit 50
   gh-axi issue view <n> -R <REPO> --full
   ```
   **Screen each candidate against fresh `main` first** — many "open" issues are
   already shipped but never closed. Grep merged history and the issue's named source
   file: `git -C <LOCAL_PATH> log --oneline main | grep -i <keywords>` and inspect the
   file. **Skip** anything already implemented (flag it for the user to close) and
   anything needing infra the app lacks. Also skip any issue another concurrent clone
   is actively working (check sibling checkouts' branches). Pick the single
   highest-value, genuinely-unimplemented, in-scope, self-contained issue.

2. **Implement via gnhf** (fresh worktree off `main`, fresh context). Build the worker
   prompt by substituting the profile's `{{PLACEHOLDERS}}` into the template and
   appending the issue, then pipe it in:
   ```sh
   { sed -e 's/{{APP_NAME}}/.../' -e ... ~/.claude/skills/overnight-issue-loop/prompt-template.md; \
     echo; echo "## The issue to implement"; \
     gh-axi issue view <n> -R <REPO>; } | gnhf \
       --agent claude --worktree --prevent-sleep on --max-iterations 6 \
       --stop-when "issue #<n> is implemented; <VERIFY_COMMANDS> all pass; the work is committed on the gnhf feature branch; nothing pushed/PR'd/merged"
   ```
   Run it in the background and **monitor** it (a run exceeds the foreground timeout).
   Substitute `VERIFY_COMMANDS` literally so the worker never guesses at commands.

3. **Gate it (supervisor, with judgment).** First inspect the gnhf branch's diff vs
   `main` — confirm it's in scope and sane. Then honor the profile's `GATE_NOTES`
   (e.g. for throughline, make the branch available in the primary checkout first:
   free the gnhf worktree if it holds the branch, then `git -C <LOCAL_PATH> checkout <branch>`).
   Then drive the gate — see below.

4. **Merge + sync.** On a clean `passed`/`checks-passed`, merge the PR to main and
   sync local main:
   ```sh
   gh-axi pr merge <pr> -R <REPO> --squash --delete-branch
   git -C <LOCAL_PATH> checkout main && git -C <LOCAL_PATH> pull origin main
   ```

5. **Handoff notes.** Append gotchas/good-to-knows for the next iteration to the loop's
   `notes.md` (gnhf also maintains its own per-worktree notes).

6. **Next issue** → step 1.

## Driving the gate  ⚠️ KNOWN LIMITATION for unattended runs

**The gate cannot currently be triggered headlessly.** Verified empirically
(2026-07-03): with a committed branch checked out in the primary checkout,
`no-mistakes axi run --intent "..."` returns `error: no run started ... no previous
run for branch`. `axi run` only *drives* an existing run — it does **not** create
one. A run is **triggered only by `git push no-mistakes <branch>` through the push
shim**, and:

- When an **agent** runs that push, it **bypasses the shim** — writes the ref
  without triggering a run, and *blocks* the real trigger. So the agent must NOT
  `git push no-mistakes` itself.
- The shim fires only in the **user's interactive shell**. So triggering the gate is
  currently a **human step**.

**Consequence:** this loop is **semi-attended at the gate**. The worker implements +
commits autonomously; then the host **hands the user the exact push command** and
waits:
```
cd <LOCAL_PATH> && git push no-mistakes <branch>
```
If that push reports **"Everything up-to-date"** and no run appears (check
`git ls-remote no-mistakes` shows the ref but `no-mistakes axi` lists no run for the
branch), the ref is already on the proxy so the shim saw no change and didn't fire.
Have the user **delete + re-push** to force a fresh trigger:
```
git push no-mistakes :<branch>      # delete stale ref on the proxy
git push no-mistakes <branch>       # re-push → shim fires
```
(This most often happens when an agent's earlier `axi run` or push already wrote the
ref. It's the trap that becomes the endless re-push spiral if done blindly — do the
delete+repush once, then monitor; don't loop it.)

After the user pushes, the no-mistakes proxy owns the pipeline (review → test →
document → lint → push → PR → CI). The host then **monitors** `no-mistakes axi status`
(do NOT drive with `axi run`/`respond` — per global CLAUDE.md, agent-driven axi
fails/stalls the majority of the time):
- lands on `passed`/`checks-passed` with a PR → merge (rail 3).
- stops at an `ask-user` finding → surface it to the user; do not merge (rail 4).

**Do not spiral.** If the gate errors or stalls, **stop and report/file an issue** —
never re-push/`daemon restart` in a loop. (A stale-daemon `"no previous run"` after an
`init` is a separate, rarer case fixable with `daemon restart`; don't conflate it with
the normal "not triggered yet" state.)

**Fully-unattended operation is an OPEN PROBLEM:** it needs a headless trigger that
goes through the shim (or an equivalent). Until that exists, an "overnight" run still
needs a human to push at each gate. Flag this to the user rather than pretending the
loop is end-to-end autonomous.

## Common mistakes

- **Worker runs no-mistakes / merges.** It must only implement + verify + commit.
- **Worker launches/drives the app to verify.** Forbidden — that's the token spiral.
  Verify with the profile's commands only.
- **Skipping the preflight.** Always confirm the baseline builds+tests on `main`
  before spawning a worker.
- **Inventing verify commands.** Use only what the repo actually has (throughline has
  no `lint`/`typecheck`).
- **Agent-pushing to the `no-mistakes` remote / driving `axi run`.** The agent push
  bypasses the shim and blocks the trigger; `axi run` errors "no previous run". The
  gate is triggered by the **user's** shimmed `git push no-mistakes <branch>` — hand
  it to them, then monitor (see "Driving the gate").
- **Pretending the loop is fully unattended.** It is semi-attended at the gate until a
  headless trigger exists. Say so.
- **Re-doing a shipped issue.** Screen every candidate against `main` first.
- **Colliding with a concurrent clone.** Check sibling checkouts' active branches so
  two loops don't work the same issue.
- **Letting a flaky gate spin.** Bound the attempts; stop + file an issue instead.
- **Assuming the backlog stays shippable.** Clean self-contained issues run out fast;
  stop early rather than force an epic.
