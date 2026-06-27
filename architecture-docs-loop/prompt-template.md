<!--
  Worker prompt for ONE repo of the architecture-docs loop.
  gnhf runs this in a --worktree of the target repo (cwd = the repo).
  Default exemplar + target dir are hardcoded to Richard's setup;
  change «EXEMPLAR» / repo references if reusing elsewhere.
  Pipe into gnhf:  cat this-file.md | gnhf --agent claude --worktree --stop-when "..."
-->

You are running gnhf to document the architecture of the codebase in THIS
directory (your cwd is a dedicated git worktree of the repo). Your single job:
produce a human-readable mental map of this codebase as TWO files, then stop.
gnhf commits your work — you must NEVER run git commit/push or open a PR. Work
subagent-driven: dispatch focused subagents to explore the code so your own
context stays lean, then assemble the docs yourself.

## The deliverables (both required, in this repo's `docs/`)

1. **`docs/ARCHITECTURE.md`** — the prose mental map.
2. **`docs/architecture.html`** — an interactive page (daisyUI + Mermaid),
   built with the **lavish** skill. This is the centerpiece.

## 1. Study the gold-standard exemplar FIRST
Before writing anything, read both of these and mirror their structure, depth,
and tone — this is the quality bar, not a loose suggestion:
- `/Users/richardschmidt/Code/play/iron_key/docs/architecture.html`
- `/Users/richardschmidt/Code/play/iron_key/docs/ARCHITECTURE.md`

The winning shape (reproduce it for THIS repo):
- **Hero** — what this app is, in two plain sentences.
- **The one big idea** — the single concept that explains the whole layout.
- **The layered map** — a Mermaid `flowchart` of the layers/modules and how they
  depend on each other.
- **Module cards** — one card per significant module/dir: what it's responsible
  for, badged by layer (e.g. core / cli / ui / server).
- **Key mental-model diagram(s)** — a Mermaid diagram for whatever central concept
  this codebase has (the equivalent of iron_key's "envelope encryption").
- **Common use cases, end to end** — the most important part. For EACH primary
  user action, a numbered Mermaid `sequenceDiagram` tracing the action through the
  actual code components (files/functions), so a reader sees what touches what and
  how data flows end to end.
- **Design principles** — the patterns you see repeated across the code.
- **Keeping this document current** — a short note on how to update it.

## 2. Explore this repo (subagent-driven) to build an accurate map
Dispatch subagents to map: entry points, the layer/module boundaries, the data
stores and external services, and the real call paths for each primary user
use-case. Read the repo's own README / CLAUDE.md / CONTEXT.md / docs and recent
commits for intent. Every diagram must reflect the ACTUAL code (real file and
function names) — never invent components. When unsure how a flow works, trace it
in the code rather than guessing.

## 3. Pick the use-cases that matter
Identify this app's primary user actions (e.g. for a CLI: each command; for a web
app: sign-in, the core create/read/update flows, the money/data-moving flows).
Give each its own end-to-end `sequenceDiagram`. Aim for the handful that give a
newcomer the real mental map — not an exhaustive catalogue of every endpoint.

## 4. Build the HTML with lavish, keep it self-contained and rendering
- Use the lavish skill to author/preview `docs/architecture.html`.
- Mermaid via CDN + `mermaid.initialize`, exactly like the exemplar; every
  `<pre class="mermaid">` block must be valid Mermaid that renders (no syntax
  errors). Verify diagrams parse before finishing.
- Keep `ARCHITECTURE.md` in sync with the HTML (same sections, Mermaid in fenced
  code blocks).

## 5. Finish the iteration cleanly
- Write both files under `docs/`. Do NOT modify any source code — the only changes
  this run makes are the two new doc files.
- Stop any preview servers/processes you started.
- Report what you produced: the sections covered and the list of use-case flows.
  gnhf will commit the two files. Do NOT git commit/push/PR yourself.

Stop only when: `docs/ARCHITECTURE.md` and `docs/architecture.html` both exist and
are committed, the HTML renders the layered map plus a Mermaid sequenceDiagram for
every primary use-case, and both mirror the iron_key exemplar's structure/quality.
