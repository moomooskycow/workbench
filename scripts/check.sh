#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

shell_sources=()
while IFS= read -r shell_source; do
  shell_sources+=("$shell_source")
done < <(
  while IFS= read -r tracked_file; do
    if [[ "$tracked_file" == dotfiles/* ]]; then
      continue
    fi

    if [ -r "$tracked_file" ] && IFS= read -r first_line < "$tracked_file"; then
      if [[ "$first_line" == "#!/bin/bash"* ]] ||
        [[ "$first_line" == "#!/usr/bin/env bash"* ]] ||
        [[ "$first_line" == "#!/bin/sh"* ]] ||
        [[ "$first_line" == "#!/usr/bin/env sh"* ]]; then
        printf '%s\n' "$tracked_file"
      fi
    fi
  done < <(git ls-files)
)

if [ "${#shell_sources[@]}" -eq 0 ]; then
  echo "No tracked shell scripts found." >&2
  exit 1
fi

echo "Checking shell syntax..."
bash -n "${shell_sources[@]}"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck is required for the full gate. Install it, then rerun scripts/check.sh." >&2
  exit 1
fi

echo "Checking ShellCheck error-level findings..."
shellcheck -S error "${shell_sources[@]}"

"$ROOT_DIR/scripts/test-op-agent.sh"

echo "Workbench gate passed."
