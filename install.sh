#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE=""
APPLY=false
ADOPT=false

usage() {
  cat <<'EOF'
Usage: ./install.sh --profile serenity|mirrodin [--apply] [--adopt]

The default is a read-only plan. --apply installs an immutable snapshot under
~/.local/share/workbench/releases. Existing unmanaged files are never replaced
unless --adopt is also supplied; adopted files are backed up first.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift 2 ;;
    --apply) APPLY=true; shift ;;
    --adopt) ADOPT=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$PROFILE" in serenity|mirrodin) ;; *) usage >&2; exit 2 ;; esac

MANIFEST="$ROOT_DIR/config/hosts/$PROFILE/manifest.tsv"
STAMP="$(date +%Y%m%dT%H%M%S)"
REVISION="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || printf snapshot)"
RELEASE="$HOME/.local/share/workbench/releases/${REVISION}-${PROFILE}-${STAMP}"
BACKUP="$HOME/.local/state/workbench/backups/${STAMP}-${PROFILE}"

while IFS='|' read -r item source target; do
  [[ "$item" == \#* ]] && continue
  [ -n "$source" ] || continue
  target="$HOME/$target"
  printf '%-9s %-14s %s -> %s\n' "$PROFILE" "$item" "$source" "$target"
done < "$MANIFEST"

if [ "$APPLY" != true ]; then
  echo "Plan only. Re-run with --apply; add --adopt to preserve and replace existing unmanaged files."
  exit 0
fi

mkdir -p "$RELEASE" "$BACKUP"
cp -R "$ROOT_DIR/config/." "$RELEASE/config"

while IFS='|' read -r item source target; do
  [[ "$item" == \#* ]] && continue
  [ -n "$source" ] || continue
  target="$HOME/$target"
  release_source="$RELEASE/$source"
  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ] && [[ "$(readlink "$target")" == "$HOME/.local/share/workbench/releases/"* ]]; then
    rm "$target"
  elif [ -e "$target" ] || [ -L "$target" ]; then
    if [ "$ADOPT" != true ]; then
      echo "Refusing unmanaged target: $target (use --adopt to back it up)" >&2
      exit 1
    fi
    backup_target="$BACKUP/${target#"$HOME"/}"
    mkdir -p "$(dirname "$backup_target")"
    mv "$target" "$backup_target"
  fi
  ln -s "$release_source" "$target"
done < "$MANIFEST"

printf '%s\n' "$RELEASE" > "$HOME/.local/state/workbench/current-$PROFILE"
echo "Installed $PROFILE profile. Backup: $BACKUP"
