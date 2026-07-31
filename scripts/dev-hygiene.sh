#!/bin/bash

set -euo pipefail

DEVELOPMENT_DIR="$HOME/Development"
LOG_DIR="$HOME/.config/workbench"
LOG_FILE="$LOG_DIR/dev-hygiene.log"
RUN_AT="$(date '+%Y-%m-%dT%H:%M:%S%z')"

mkdir -p "$LOG_DIR"

repo_count=0
unpushed_repo_count=0
dirty_repo_count=0

printf 'Development hygiene run: %s\n' "$RUN_AT"

if [ -d "$DEVELOPMENT_DIR" ]; then
  for repo_dir in "$DEVELOPMENT_DIR"/* "$DEVELOPMENT_DIR"/.[!.]* "$DEVELOPMENT_DIR"/..?*; do
    [ -d "$repo_dir" ] || continue
    if ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      continue
    fi
    # Some layouts (e.g. bare-flagged repos with worktree checkouts) pass the
    # check above but fail individual commands. One bad repo must not kill the run.

    repo_name="$(basename "$repo_dir")"
    repo_count=$((repo_count + 1))
    git -C "$repo_dir" worktree prune 2>/dev/null \
      || printf 'WARN %s: worktree prune failed\n' "$repo_name"

    unpushed_count="$( (git -C "$repo_dir" log --branches --not --remotes --oneline 2>/dev/null || true) | wc -l)"
    if [ "$unpushed_count" -gt 0 ]; then
      unpushed_repo_count=$((unpushed_repo_count + 1))
      printf 'UNPUSHED %s: %s commit(s)\n' "$repo_name" "$unpushed_count"
    fi

    dirty_files="$(git -C "$repo_dir" status --short 2>/dev/null || true)"
    if [ -n "$dirty_files" ]; then
      dirty_repo_count=$((dirty_repo_count + 1))
      printf 'DIRTY %s:\n%s\n' "$repo_name" "$dirty_files"
    fi
  done
else
  printf 'Development directory not found: %s\n' "$DEVELOPMENT_DIR"
fi

printf '%s repos=%s unpushed_repos=%s dirty_repos=%s\n' \
  "$RUN_AT" "$repo_count" "$unpushed_repo_count" "$dirty_repo_count" | tee -a "$LOG_FILE"
