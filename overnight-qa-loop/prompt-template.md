<!--
  Worked prompt for an overnight gnhf QA bug-hunt loop.
  This is the EXACT shape that worked on budget-app, generalized.
  Replace every «PLACEHOLDER». Delete instructions that don't apply.
  Pipe the finished file into gnhf:  cat this-file.md | gnhf --stop-when "..." --worktree
-->

You are running ONE iteration of an unattended overnight QA loop for «APP NAME»
(repo: this directory). Your job: drive the app as a real user, find ONE genuine
bug or clear UX win, fix it well, and stop. gnhf commits your work — you must
NEVER run git commit/push or open a PR. Work subagent-driven: dispatch focused
subagents for the heavy exploration and the fix, keep your own context lean.

## 1. Ensure the ISOLATED QA environment is up (idempotent — skip what's already satisfied)
This loop runs a dedicated sandbox instance on its own ports — NEVER the
production/dev server «e.g. :5173/:3001» and NEVER the user's real data.
- Datastore: «how to bring up an isolated DB, e.g. `npm run db:up` (Docker)».
- App on «QA web port» + «QA api port», «sandbox/fake external services», env file «.env.qa»:
  if «QA web port» is not already listening, start «e.g. `npm run dev:qa`» in the
  background. It must load «.env.qa» and apply migrations on boot.
- Dedicated QA account, isolated from real data:
  - «credentials, e.g. Email: qa-bot@example.test  Password: ...»
  - Create it if missing via «the app's signup route/path».
  - It must have «realistic seeded data» so real-shaped content exists. Seed it
    via «the fastest non-UI path, e.g. a sandbox API + the app's authenticated
    import route — read «relevant route file» for the exact payload».
  - Idempotency: if the QA account already has data, skip all setup.
  - NEVER touch any account other than the QA one. NEVER modify real data.

## 2. Read notes.md (if it exists) FIRST
It is the running ledger of every finding from prior iterations. Do not re-report
or re-fix anything already listed (fixed OR logged-only). Pick something new.

## 3. Drive the app as the QA user via «browser-driving tool» against «QA URL»
Log in, then walk the screens looking for problems: «list the routes/screens».
Watch for: JS console errors, network errors, crashes, broken/incorrect behavior,
bad empty/error/loading states, and clearly confusing UX.

## 4. Pick exactly ONE new finding and classify it against the fix bar
- COSMETIC NIT (subjective polish, minor spacing/wording): record it in your
  iteration report as logged-only and DO NOT change any code. Does not count
  toward the stop condition.
- REAL BUG or CLEAR UX WIN (broken behavior, errors, bad states, high-confidence
  UX improvement): proceed to fix it.
Bias toward reproducible bugs and console/network errors over subjective UX.

## 5. Fix it with TDD (red -> green -> refactor)
Write a failing test that captures the bug/behavior, make it pass with the
smallest correct change, refactor. Then validate: «test command» AND «lint
command» must both pass. Keep the change scoped to this one finding — no
unrelated refactoring.

## 6. Finish the iteration cleanly
- Stop any background processes YOU started for verification (leave the dev
  server running).
- Report a structured result describing: the finding, the screen, the
  classification (fixed / logged-only), the fix, and test/lint status. gnhf will
  commit a fixed change and append to notes.md. Do NOT git commit/push/PR yourself.

If you cannot find any NEW qualifying issue this iteration, say so plainly in your
report so the run can wind down — do not invent low-value churn.
