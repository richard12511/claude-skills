---
name: overnight-issue-loop
description: Use when the user wants an unattended overnight loop that works through a repo's open GitHub issues one at a time — picking the highest-value issue, implementing it, gating it through no-mistakes, and merging — and asks to run, kick off, or resume the "overnight issue loop". Currently tuned for next_rep_mobile.
---

# Overnight Issue Loop

## Overview

An unattended loop that ships open GitHub issues one at a time. It is a **hybrid**
of two engines, split by who holds judgment:

- **gnhf implements** each issue in an isolated `--worktree` with fresh context per
  issue (and `notes.md` handoff between issues). The worker writes a spec, codes it
  subagent-driven, and verifies locally — but it does **not** gate, push, PR, or merge.
- **The host agent (you) supervises the irreversible parts**: drive the
  `no-mistakes` gate with judgment, then merge clean PRs to main and sync.

This split exists because the safety rail — **stop if anything looks iffy** — lives
at `no-mistakes`'s `ask-user` gate, which needs a human-escalable supervisor that a
headless worker can't be.

**REQUIRED BACKGROUND:**
- The **gnhf** engine — read the `gnhf` skill (`$(npm root -g)/gnhf/skills/gnhf/SKILL.md`). Run each issue in gnhf **Hands-Off** mode.
- The **no-mistakes** gate — read the `no-mistakes` skill. You drive it via `no-mistakes axi run`.

The per-issue worker prompt is in [prompt-template.md](prompt-template.md).

## The rails (don't violate)

1. **Cap: 3 issues per run** (first-run setting). Stop early if no eligible issue
   remains or the gate keeps failing.
2. **Eligibility: UI/UX issues only.** Exclude pure infra/backend (for
   next_rep_mobile that's #4 EAS client, #6 API URL, #18 server cleanup).
3. **Merge only on a clean gate.** A `no-mistakes` outcome of `checks-passed` (or
   `passed`) with a sane diff → merge. Anything else → don't merge.
4. **Stop-if-iffy = skip that issue and continue.** If an `ask-user` finding or the
   diff looks off, do NOT merge: leave the PR/branch, write a note, move to the next
   issue. Do not halt the whole run.
5. **The worker never gates, pushes, PRs, or merges** — that's the supervisor's job.

## The loop (host agent runs this)

Repeat until 3 issues are merged, or no eligible issue remains:

1. **Pick the issue (step 0).** List open issues, choose the single highest UI/UX
   value one that isn't already shipped:
   ```sh
   gh-axi issue list -R <owner>/<repo> --state open --limit 50
   ```
   Read the chosen issue in full (`gh-axi issue view <n> -R <owner>/<repo>`).

2. **Implement via gnhf** (fresh worktree, fresh context). Build the worker prompt
   by appending the issue's number/title/body to the template, and pipe it in:
   ```sh
   { cat ~/.claude/skills/overnight-issue-loop/prompt-template.md; \
     echo; echo "## The issue to implement"; \
     gh-axi issue view <n> -R <owner>/<repo>; } | gnhf \
       --agent claude --worktree --prevent-sleep on --max-iterations 12 \
       --stop-when "issue #<n> is implemented; npm run typecheck, npm run lint, and npm test all pass; the work is committed on the gnhf feature branch; nothing pushed/PR'd/merged"
   ```
   Run it in the background (a run exceeds the foreground command timeout).

3. **Gate it (supervisor, with judgment).** `cd` into the gnhf worktree, then:
   ```sh
   no-mistakes axi run --intent "<the issue goal + the key decisions/tradeoffs the worker made>"
   ```
   **Without `--yes`** — drive each gate yourself. For `auto-fix`/`no-op` findings,
   respond `--action fix`/`approve`. For an `ask-user` finding or a diff that looks
   off → **iffy**: abort/leave the run, write a note, and **skip to the next issue**
   (rail 4). The review/test/CI steps each take minutes — allow long timeouts.

4. **Merge + sync.** On a clean `checks-passed`/`passed`, merge the PR to main and
   sync local main:
   ```sh
   gh-axi pr merge <pr> -R <owner>/<repo> --squash --delete-branch
   git -C <repo> checkout main && git -C <repo> pull origin main
   ```

5. **Handoff notes.** Append gotchas/good-to-knows for the next iteration to the
   loop's `notes.md` (gnhf also maintains its own per-worktree notes).

6. **Next issue** → step 1.

## Picking the highest-UI/UX-value issue

Favor issues that visibly improve the user's experience and are self-contained
enough to ship cleanly in one cycle: broken/awkward interactions, missing-but-
expected affordances, dead-end screens. Deprioritize large multi-surface epics and
anything not user-facing. When two are close, prefer the one that removes a clear
friction point a real user hits first.

## Common mistakes

- **Worker runs no-mistakes / merges.** It must only implement + verify + commit.
  Gate and merge are the supervisor's, where stop-if-iffy judgment lives.
- **Using `--yes` on the gate.** That auto-resolves `ask-user` findings, defeating
  stop-if-iffy. Drive gates manually for this loop.
- **Worker invokes the superpowers `brainstorming` skill.** It hard-gates on user
  approval and will stall the unattended run. The worker does brainstorming-style
  *reasoning* (pros/cons, self-decide favoring UX) without the approval gate.
- **Merging an iffy diff to keep momentum.** Skip-and-continue instead; leave it for
  morning review.
- **Picking infra/backend issues.** UI/UX only for this loop.
- **Re-doing a shipped issue.** Check it's still open and not covered by a recent
  merged PR before picking.
