---
name: architecture-docs
description: Use when the user wants human-readable architecture documentation for ONE repo (an interactive HTML page with Mermaid diagrams + a markdown twin, including end-to-end user use-case flows) generated or refreshed in place, on demand — or asks to reuse the iron_key "architecture map" docs on the current/a single project. For documenting every repo in a directory as a long-running loop, use architecture-docs-loop instead.
---

# Architecture Docs (single repo)

## Overview

Produce a human-readable mental map of **one** codebase as TWO files under its
`docs/`: `docs/ARCHITECTURE.md` (prose) and `docs/architecture.html` (an
interactive daisyUI + Mermaid page with the layered map, module cards, and an
end-to-end flow diagram per user use-case). If the files already exist, this
**refreshes** them.

**This is the in-place, on-demand variant.** You (the current session) do the
work directly in the repo's working tree — no gnhf, no worktree, no repo-to-repo
loop. When done you **leave the two files uncommitted for the user to review and
commit** — do NOT `git commit`/`push`/PR, and do NOT run the no-mistakes gate
(docs are low-risk; the goal is a diff the user eyeballs, not a merged PR).

**When NOT to use:** documenting *every* repo in a directory → use
`architecture-docs-loop` (that one drives gnhf per repo in worktree isolation).

**REQUIRED BACKGROUND:** the **lavish** skill — you use it to build and preview
`docs/architecture.html`.

## The deliverables (both required, in this repo's `docs/`)

1. **`docs/ARCHITECTURE.md`** — the prose mental map (Mermaid in fenced blocks).
2. **`docs/architecture.html`** — an interactive page (daisyUI + Mermaid), built
   with the **lavish** skill. This is the centerpiece.

Both go **directly under `docs/`** — not `docs/architecture/` or any subfolder —
matching the exemplar exactly.

## 1. Study the gold-standard exemplar FIRST

Before writing anything, read both of these and mirror their structure, depth,
and tone — this is the quality bar, the single biggest quality lever, not a loose
suggestion:

- `/Users/richardschmidt/Code/play/iron_key/docs/architecture.html`
- `/Users/richardschmidt/Code/play/iron_key/docs/ARCHITECTURE.md`

The winning shape (reproduce it for THIS repo):

- **Hero** — what this app is, in two plain sentences.
- **The one big idea** — the single concept that explains the whole layout.
- **The layered map** — a Mermaid `flowchart` of the layers/modules and how they
  depend on each other.
- **Module cards** — one card per significant module/dir: what it's responsible
  for, badged by layer (e.g. core / cli / ui / server).
- **Key mental-model diagram(s)** — a Mermaid diagram for whatever central
  concept this codebase has (the equivalent of iron_key's "envelope encryption").
- **Common use cases, end to end** — the most important part. For EACH primary
  user action, a numbered Mermaid `sequenceDiagram` tracing the action through the
  actual code components (files/functions), so a reader sees what touches what and
  how data flows end to end.
- **Design principles** — the patterns repeated across the code.
- **Keeping this document current** — a short note on how to update it.

## 2. Map the repo (subagent-driven) to build an accurate picture

Dispatch focused subagents so your own context stays lean, then assemble the docs
yourself. Map: entry points, the layer/module boundaries, data stores and
external services, and the real call paths for each primary use-case. Read the
repo's own README / CLAUDE.md / CONTEXT.md / docs and recent commits for intent.
Every diagram must reflect the ACTUAL code (real file and function names) — never
invent components. When unsure how a flow works, trace it in the code.

## 3. Pick the use-cases that matter

Identify this app's primary user actions (a CLI: each command; a web app: sign-in,
the core create/read/update flows, the money/data-moving flows). Give each its own
end-to-end `sequenceDiagram`. Aim for the handful that give a newcomer the real
mental map — not an exhaustive catalogue of every endpoint.

## 4. Build the HTML with lavish; keep it self-contained and rendering

- Use the **lavish** skill to author and preview `docs/architecture.html`.
- Mermaid via CDN + `mermaid.initialize`, exactly like the exemplar; every
  `<pre class="mermaid">` block must be valid Mermaid that renders (no syntax
  errors). **Verify diagrams parse before finishing** — a page with a broken
  diagram is a failed run.
- Keep `ARCHITECTURE.md` in sync with the HTML (same sections, Mermaid fenced).

## 5. Finish — leave it for the user to review

- Write both files under `docs/`. Do NOT modify any source code — the only changes
  this run makes are the two doc files.
- Stop any preview servers/processes you started.
- **Leave the files uncommitted.** Report what you produced (sections covered +
  the list of use-case flows) and tell the user to review the diff and commit.
  Do NOT `git commit`/`push`/open a PR/run no-mistakes yourself.

## Common mistakes

- **Wrong path.** Files go directly in `docs/` (`docs/ARCHITECTURE.md`,
  `docs/architecture.html`) — not a `docs/architecture/` subfolder.
- **Committing or gating.** This variant leaves the docs in the working tree for
  the user. Don't commit, push, PR, or run no-mistakes — docs are low-risk.
- **Skipping the exemplar.** Without studying iron_key's page first, you produce a
  flat file list instead of a layered map with end-to-end use-case flows. The
  exemplar IS the spec.
- **Broken Mermaid.** A `<pre class="mermaid">` with a syntax error silently fails
  to render. Verify every diagram parses before finishing.
- **Inventing components.** Diagrams must use real file/function names traced from
  the code, not a plausible-sounding guess.
- **Reaching for gnhf / a worktree / the loop.** That's the multi-repo variant.
  Here you work in place in this session.
