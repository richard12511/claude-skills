---
name: architecture-docs-loop
description: Use when the user wants to auto-generate human-readable architecture documentation (an interactive HTML page with Mermaid diagrams + a markdown twin, including end-to-end user use-case flows) across every repo in a directory, one repo at a time, as a long-running gnhf-driven loop — or asks to reuse the iron_key "architecture map" docs generator on their other projects.
---

# Architecture Docs Loop

## Overview

A long-running loop that walks every git repo in a directory and, **one repo at a
time**, produces a mental-map of that codebase: `docs/ARCHITECTURE.md` (prose) and
`docs/architecture.html` (an interactive daisyUI + Mermaid page with the layered
map, module cards, and an end-to-end flow diagram per user use-case).

The **per-repo engine is gnhf** — one gnhf run per repo, in `--worktree` isolation,
commits the docs on its own branch. The **outer repo-to-repo loop is THIS skill**,
driven by the host agent: discover the next undocumented repo → run gnhf on it →
clear/compact → next repo → stop when none remain. Running one repo per gnhf run
gives a fresh worker (and a natural compaction boundary) for every codebase.

**REQUIRED BACKGROUND:**
- The **gnhf** engine and its Hands-Off mode — read the `gnhf` skill (bundled at
  `$(npm root -g)/gnhf/skills/gnhf/SKILL.md`). Each repo runs in gnhf **Hands-Off** mode.
- The **lavish** skill — the worker uses it to build/preview the HTML artifact.

The proven worker prompt is in [prompt-template.md](prompt-template.md).

## The five things that make it work

1. **One gnhf run per repo, with `--worktree`.** The repos are live (often on active
   feature branches). `--worktree` isolates the worker from any other agent on that
   repo, and gnhf creates **its own branch off current HEAD** — so the docs never
   land on the in-progress feature branch. You review/merge each gnhf branch later.
2. **The worker never pushes or PRs — gnhf commits.** The prompt forbids the worker
   from `git commit`/`push`/PR. (Do NOT bolt `no-mistakes` onto the worker; docs
   are low-risk and the goal is branches to review, not merged PRs.)
3. **Match the iron_key exemplar.** `~/Code/play/iron_key/docs/architecture.html` +
   `ARCHITECTURE.md` are the gold standard for structure and quality. The worker
   studies them first and mirrors them. This is the single biggest quality lever.
4. **The filesystem is the ledger.** A repo is DONE when `docs/architecture.html`
   exists in its working tree **or any committed branch** (so a prior gnhf run that
   left it on a gnhf branch still counts). Never re-document a done repo.
5. **One repo at a time, clear/compact between repos.** Finish a repo fully, then
   compact context before the next so each codebase starts fresh.

## The outer loop (host agent runs this)

1. **Discover the next undocumented repo** in the target dir (default `~/Code/play`):

   ```sh
   PLAY="${PLAY:-$HOME/Code/play}"
   for d in "$PLAY"/*/; do
     d="${d%/}"
     [ -d "$d/.git" ] || continue
     if [ -e "$d/docs/architecture.html" ] || \
        git -C "$d" log --all --oneline -- docs/architecture.html 2>/dev/null | grep -q .; then
       continue   # DONE — skip (this is the ledger)
     fi
     echo "$d"     # TODO
   done
   ```

2. **Run gnhf on the first TODO repo** (see Launch below). Wait for it to exit.

3. **Verify** the repo is now done — both files committed on the gnhf branch:

   ```sh
   git -C "$REPO" log --all --oneline -- docs/architecture.html | head -1
   git -C "$REPO" log --all --oneline -- docs/ARCHITECTURE.md   | head -1
   ```

   If gnhf exited without committing both, treat it as a failed iteration: inspect
   the gnhf branch/notes and relaunch with a tightened prompt (name the specific
   gap — e.g. "the HTML has no use-case sequenceDiagrams" — as the focus). Give a
   repo **at most 2 relaunches**; if it still fails, log it as skipped-with-reason
   and move on rather than blocking the whole loop.

4. **Clear/compact, then go to step 1** for the next repo. Repo order is just the
   glob order (alphabetical) — which repo goes first doesn't matter; all get done.

5. **Stop** when step 1 prints nothing (every repo documented).

## Launch (per repo)

`cd` into the repo, then pipe the filled template into gnhf. `--worktree` is
mandatory (isolation); do NOT pass `--current-branch` (that would put docs on the
live feature branch).

```sh
cd "$REPO"
cat ~/.claude/skills/architecture-docs-loop/prompt-template.md | gnhf \
  --agent claude \
  --worktree \
  --prevent-sleep on \
  --max-iterations 8 \
  --stop-when "docs/ARCHITECTURE.md AND docs/architecture.html are both committed; the HTML renders the layered architecture map and a Mermaid sequenceDiagram for every primary user use-case; both mirror the structure/quality of ~/Code/play/iron_key/docs/architecture.html"
```

Run metadata (prompt, notes, transcripts) lands in `.gnhf/runs/<slug>/` in the
worktree (gitignored).

**Unattended (overnight) launch:** for a fire-and-forget run that doesn't depend on
a live Claude session, use the bundled driver script — it is the whole outer loop
in bash (discover → gnhf per repo → verify → next):

```sh
~/.claude/skills/architecture-docs-loop/run.sh --dry-run   # preview which repos
~/.claude/skills/architecture-docs-loop/run.sh             # run the loop (~/Code/play)
~/.claude/skills/architecture-docs-loop/run.sh /other/dir  # a different directory
```

**Interactive (host-agent-driven) launch:** when supervising quality run by run,
the host agent drives the loop itself — but it MUST start each gnhf run as a
**background** process (a per-repo run exceeds the foreground command timeout) and
proceed when notified of completion.

## Reusing it on a different directory

Set `PLAY` to the target directory in the discovery loop and the launch. The
iron_key exemplar path is the quality anchor — keep pointing the worker at a single
known-good `architecture.html`, even when documenting repos elsewhere, until the
target dir has its own exemplar.

## Review when the run finishes

Each repo has a gnhf branch with the docs committed in a worktree. To review:

```sh
git -C "$REPO" branch --list 'gnhf*'                 # find the branch
git -C "$REPO" worktree list                          # find the worktree path
open "$WORKTREE/docs/architecture.html"               # eyeball the page
```

Merge the branches you're happy with; re-run a repo (after `git checkout -- ` /
deleting its `docs/architecture.html`) if a page came out weak. Once a branch is
merged, clean up its worktree with `git -C "$REPO" worktree remove "$WORKTREE"` so
they don't accumulate (the branch survives the worktree removal).

## Common mistakes

- **Forgetting `--worktree`** → the worker mutates the live checkout another agent
  is using, or commits docs onto an in-progress feature branch. Always isolate.
- **Letting the worker push/PR.** gnhf commits; the worker must not. Don't add a
  push gate or `no-mistakes` to the worker prompt.
- **Skipping the exemplar.** Without studying iron_key's page, the worker produces a
  flat file list instead of a layered map with end-to-end use-case flows. The
  exemplar IS the spec.
- **Batching repos in one gnhf run / one context.** One repo per run. More than one
  produces tangled work and no compaction boundary.
- **Re-documenting a done repo.** Use the ledger check (working tree OR any branch),
  not just "is the file in the current checkout" — a prior gnhf branch counts.
- **Vague stop condition.** "looks good" never terminates. Gate on both files
  committed + a Mermaid flow per use-case.
