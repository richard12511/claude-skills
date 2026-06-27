#!/usr/bin/env bash
# Architecture-docs loop: generate iron_key-style architecture docs
# (docs/ARCHITECTURE.md + interactive Mermaid docs/architecture.html) for every
# UNDOCUMENTED git repo in a directory, one repo at a time, via gnhf.
#
# Each repo runs in its own gnhf --worktree (isolation from live agents); gnhf
# commits the docs on its own branch off HEAD — never your active feature branch.
#
# Usage:
#   ~/.claude/skills/architecture-docs-loop/run.sh                 # loop over ~/Code/play
#   ~/.claude/skills/architecture-docs-loop/run.sh /path/to/dir    # loop over another dir
#   ~/.claude/skills/architecture-docs-loop/run.sh --dry-run       # just list TODO/SKIP, do nothing
#   PLAY=/path run.sh                                              # dir via env
set -uo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && { DRY_RUN=1; shift; }

PLAY="${1:-${PLAY:-$HOME/Code/play}}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT="$SKILL_DIR/prompt-template.md"
EXEMPLAR="$HOME/Code/play/iron_key/docs/architecture.html"
STOP="docs/ARCHITECTURE.md AND docs/architecture.html are both committed; the HTML renders the layered architecture map and a Mermaid sequenceDiagram for every primary user use-case; both mirror the structure/quality of $EXEMPLAR"

# A repo is DONE if architecture.html exists in the working tree OR any committed branch.
is_done() {
  local d="$1"
  [ -e "$d/docs/architecture.html" ] && return 0
  git -C "$d" log --all --oneline -- docs/architecture.html 2>/dev/null | grep -q . && return 0
  return 1
}

[ -d "$PLAY" ] || { echo "No such directory: $PLAY" >&2; exit 1; }
[ -f "$PROMPT" ] || { echo "Missing prompt template: $PROMPT" >&2; exit 1; }
if [ "$DRY_RUN" = 0 ] && ! command -v gnhf >/dev/null 2>&1; then
  echo "gnhf not found on PATH. Install gnhf or run with --dry-run." >&2; exit 1
fi

echo "Architecture-docs loop over: $PLAY"
[ "$DRY_RUN" = 1 ] && echo "(dry run — listing only, nothing will be generated)"
echo

todo=0
for d in "$PLAY"/*/; do
  d="${d%/}"
  [ -d "$d/.git" ] || continue
  name="$(basename "$d")"
  if is_done "$d"; then
    echo "SKIP  $name (already documented)"
    continue
  fi
  todo=$((todo + 1))
  if [ "$DRY_RUN" = 1 ]; then
    echo "TODO  $name"
    continue
  fi
  echo
  echo "==== $name : generating architecture docs ===="
  ( cd "$d" && cat "$PROMPT" | gnhf \
      --agent claude \
      --worktree \
      --prevent-sleep on \
      --max-iterations 8 \
      --stop-when "$STOP" )
  if is_done "$d"; then
    echo "DONE  $name"
  else
    echo "FAILED $name — no committed docs/architecture.html; moving on" >&2
  fi
done

echo
if [ "$DRY_RUN" = 1 ]; then
  echo "$todo repo(s) would be processed."
else
  echo "Loop complete. Review each repo's gnhf branch/worktree:"
  echo "  git -C <repo> branch --list 'gnhf*'"
  echo "  git -C <repo> worktree list"
  echo "  open <worktree>/docs/architecture.html"
fi
