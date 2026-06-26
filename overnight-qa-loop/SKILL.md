---
name: overnight-qa-loop
description: Use when the user wants an unattended or overnight autonomous loop that drives their app as a real user to find and fix bugs or UX oddities one at a time across many iterations, or asks to reuse the "overnight QA bug-hunt" / gnhf bug-finding loop on another project.
---

# Overnight QA Loop

## Overview

An unattended loop that repeatedly drives a running app as a real user, finds ONE
bug or UX defect per iteration, fixes it TDD-style, and stops at a target count.
The **engine is gnhf** — it owns the iteration mechanics (branch, per-iteration
prompt with `notes.md` memory injected, commit on success, roll back on failure,
stop condition, abort after 3 failures). This skill is the **QA-bug-hunt recipe**
that turns gnhf into a nightly tester.

**REQUIRED BACKGROUND:** the gnhf engine and its modes — read `gnhf` skill
(bundled at `$(npm root -g)/gnhf/skills/gnhf/SKILL.md`). Run this loop in
gnhf **Hands-Off** mode.

The whole "loop" is just a prompt + a stop condition. The prompt is in
[prompt-template.md](prompt-template.md) — a proven, parameterized worked example.

## The four things that make it work (and that agents get wrong without this)

1. **Hard isolation — the #1 rule.** The overnight agent must drive a DEDICATED
   instance (its own ports, its own DB, an `.env.qa`, a throwaway account, seeded
   fake/sandbox data) — **never the real dev server, never the user's real data.**
   This is the most common omission: an unguided agent points at the live app.
2. **The worker never commits.** gnhf does the committing. The prompt forbids the
   worker from `git commit`/`push`/PR. (Do NOT bolt `no-mistakes` onto the worker.)
3. **One finding per iteration + a fix bar.** Cosmetic nits → logged to `notes.md`
   only, don't count. Real bug / clear UX win → fix it. `notes.md` is read FIRST
   each iteration so nothing gets re-fixed.
4. **TDD per fix** — failing test first, then the smallest change, then validate
   test + lint.

## Launch

Fill in the template, then pipe it to gnhf (stdin handles the long prompt; use
`--worktree` so it doesn't fight your working tree or other agents):

```sh
cat prompt-template.md | gnhf \
  --agent claude \
  --stop-when "5 distinct real-bug-or-clear-UX-win fixes have been committed (cosmetic-only findings are logged to notes.md and do NOT count)" \
  --worktree \
  --prevent-sleep on
```

In the morning, review the gnhf branch's commits / open PRs. Run metadata
(prompt, `notes.md`, transcripts) lands in `.gnhf/runs/<slug>/` (gitignored).

## Reusing it on a new project

Copy `prompt-template.md` into the project and replace every `«PLACEHOLDER»`:

| Blank | What to supply |
|-------|----------------|
| App name, QA URL | The product + the isolated QA URL the agent drives |
| Isolated instance | Command to start a dedicated instance on non-default ports + its env file |
| Datastore | How to bring up an isolated DB (and that migrations run on boot) |
| QA account + seed | Throwaway credentials + the fastest NON-UI path to seed realistic data |
| Screens | The routes/screens to walk |
| Test / lint commands | The project's `test` and `lint` invocations |
| Browser tool | How the agent drives the UI (e.g. `chrome-devtools-axi`, Playwright) |

## Common mistakes

- **Driving the real app/data.** No isolated instance = the agent mutates real
  dev data and uses real third-party credentials. Always stand up the `_qa`
  instance + throwaway account first.
- **Letting the worker push/PR.** gnhf commits; the worker must not. Don't add a
  push gate to the worker prompt.
- **No `notes.md` discipline.** Without "read notes first / log don't re-fix," the
  loop re-finds the same issue every night.
- **Multi-fix iterations.** More than one fix per iteration produces tangled,
  hard-to-review commits. One finding, one commit.
- **Vague stop condition.** "looks good" never terminates. Use a countable
  condition ("N real fixes committed").
