#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="$ROOT_DIR/config/hosts/mirrodin/omarchy/plugins"
CHECKSUMS="$SOURCE_ROOT/SHA256SUMS"
TARGET_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
OMARCHY_BIN="${OMARCHY_BIN:-omarchy}"
APPLY=false
ADOPT=false
PLUGIN_IDS=(
  phaedrus.headphone-battery
  phaedrus.idle
  phaedrus.lock
  phaedrus.menu
)

declare -A ACTION=()
declare -A SOURCE_DIGEST=()
declare -A CURRENT_DIGEST=()
declare -A STAGE=()

usage() {
  cat <<'EOF'
Usage: scripts/restore-omarchy-plugins.sh [--apply] [--adopt]

The default is a read-only plan. It verifies the checked-in snapshots and
validates all four plugins without changing the plugin directory.

--apply copies validated real directories into the current user's Omarchy
plugin directory. Existing byte-and-mode-identical directories are unchanged.
A different or unowned target is refused unless --adopt is supplied; adoption
first saves the complete prior directory under XDG_STATE_HOME (or
~/.local/state), then replaces it. Symlinked targets are always refused.

This command does not edit shell.json, enable or disable plugins, invoke shell
IPC, restart the shell, or alter idle/lock/menu settings.
EOF
}

fail() {
  printf 'restore-omarchy-plugins: %s\n' "$*" >&2
  exit 1
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=true; shift ;;
    --adopt) ADOPT=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

for dependency in python3 sha256sum cp mv mktemp; do
  command -v "$dependency" >/dev/null 2>&1 || fail "Required command not found: $dependency"
done
command -v "$OMARCHY_BIN" >/dev/null 2>&1 || fail "Omarchy validator not found: $OMARCHY_BIN"
[[ -d "$SOURCE_ROOT" && ! -L "$SOURCE_ROOT" ]] || fail "Expected a non-symlink source directory: $SOURCE_ROOT"
[[ -f "$CHECKSUMS" && ! -L "$CHECKSUMS" ]] || fail "Expected checksum manifest: $CHECKSUMS"
[[ ! -L "$TARGET_ROOT" ]] || fail "Refusing symlinked plugin root: $TARGET_ROOT"
[[ ! -e "$TARGET_ROOT" || -d "$TARGET_ROOT" ]] || fail "Plugin root is not a directory: $TARGET_ROOT"

verify_source_inventory() {
  python3 - "$SOURCE_ROOT" "$CHECKSUMS" "${PLUGIN_IDS[@]}" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
checksum_path = Path(sys.argv[2])
plugin_ids = sys.argv[3:]
expected = set()
for line in checksum_path.read_text(encoding="utf-8").splitlines():
    digest, marker, rel = line.partition("  ")
    if len(digest) != 64 or not marker or not rel:
        raise SystemExit(f"invalid checksum line: {line!r}")
    expected.add(rel)

actual = set()
for plugin_id in plugin_ids:
    plugin = root / plugin_id
    if plugin.is_symlink() or not plugin.is_dir():
        raise SystemExit(f"missing or symlinked source plugin: {plugin}")
    for path in plugin.rglob("*"):
        if path.is_symlink():
            raise SystemExit(f"source symlink is not allowed: {path}")
        if path.is_dir():
            continue
        if not path.is_file():
            raise SystemExit(f"unsupported source entry: {path}")
        actual.add(path.relative_to(root).as_posix())

missing = sorted(expected - actual)
extra = sorted(actual - expected)
if missing or extra:
    raise SystemExit(f"source inventory mismatch; missing={missing}, extra={extra}")
PY
}

tree_digest() {
  python3 - "$1" <<'PY'
from pathlib import Path
import hashlib
import stat
import sys

root = Path(sys.argv[1])
if root.is_symlink() or not root.is_dir():
    raise SystemExit(f"not a real directory: {root}")
entries = []
for path in root.rglob("*"):
    if path.is_symlink():
        raise SystemExit(f"symlink is not allowed: {path}")
    if path.is_dir():
        continue
    if not path.is_file():
        raise SystemExit(f"unsupported tree entry: {path}")
    entries.append(path)

digest = hashlib.sha256()
for path in sorted(entries, key=lambda item: item.relative_to(root).as_posix()):
    rel = path.relative_to(root).as_posix().encode("utf-8")
    mode = stat.S_IMODE(path.stat().st_mode)
    data = path.read_bytes()
    digest.update(rel)
    digest.update(b"\0")
    digest.update(f"{mode:04o}".encode("ascii"))
    digest.update(b"\0")
    digest.update(len(data).to_bytes(8, "big"))
    digest.update(data)
print(digest.hexdigest())
PY
}

validate_plugin() {
  local plugin_dir="$1"
  "$OMARCHY_BIN" plugin validate "$plugin_dir" >/dev/null
}

verify_source_inventory
(
  cd "$SOURCE_ROOT"
  sha256sum --check --strict --quiet SHA256SUMS
) || fail "Checked-in plugin bytes do not match SHA256SUMS"

conflicts=()
for plugin_id in "${PLUGIN_IDS[@]}"; do
  source_dir="$SOURCE_ROOT/$plugin_id"
  target_dir="$TARGET_ROOT/$plugin_id"
  validate_plugin "$source_dir" || fail "Source validation failed: $plugin_id"
  SOURCE_DIGEST["$plugin_id"]="$(tree_digest "$source_dir")" || fail "Cannot digest source plugin: $plugin_id"

  if [[ -L "$target_dir" ]]; then
    fail "Refusing symlinked target: $target_dir"
  elif [[ ! -e "$target_dir" ]]; then
    ACTION["$plugin_id"]=install
  elif [[ ! -d "$target_dir" ]]; then
    conflicts+=("$plugin_id (target is not a directory)")
    ACTION["$plugin_id"]=conflict
  else
    CURRENT_DIGEST["$plugin_id"]="$(tree_digest "$target_dir")" || fail "Cannot inspect target plugin: $target_dir"
    if [[ "${CURRENT_DIGEST[$plugin_id]}" == "${SOURCE_DIGEST[$plugin_id]}" ]]; then
      ACTION["$plugin_id"]=unchanged
    elif [[ "$ADOPT" == true ]]; then
      ACTION["$plugin_id"]=replace
    else
      ACTION["$plugin_id"]=conflict
      conflicts+=("$plugin_id")
    fi
  fi
  printf '%-28s %s\n' "$plugin_id" "${ACTION[$plugin_id]}"
done

if [[ "${#conflicts[@]}" -gt 0 ]]; then
  printf 'Conflicting targets: %s\n' "${conflicts[*]}" >&2
  fail "No plugin targets were changed. Re-run with --adopt to back up and replace real directories; move symlinks aside manually."
fi

if [[ "$APPLY" != true ]]; then
  printf 'Plan only. No changes made. Re-run with --apply to copy the validated snapshots.\n'
  exit 0
fi

mkdir -p -- "$TARGET_ROOT"
[[ -d "$TARGET_ROOT" && ! -L "$TARGET_ROOT" ]] || fail "Could not create a real plugin root: $TARGET_ROOT"

cleanup_stages() {
  local plugin_id stage
  for plugin_id in "${PLUGIN_IDS[@]}"; do
    stage="${STAGE[$plugin_id]:-}"
    if [[ -n "$stage" && -e "$stage" && "$stage" == "$TARGET_ROOT"/.workbench-plugin-stage.* ]]; then
      rm -rf -- "$stage"
    fi
  done
}
trap cleanup_stages EXIT

# Stage and validate every changed plugin before touching a named target.
for plugin_id in "${PLUGIN_IDS[@]}"; do
  [[ "${ACTION[$plugin_id]}" != unchanged ]] || continue
  stage="$(mktemp -d "$TARGET_ROOT/.workbench-plugin-stage.XXXXXX")"
  STAGE["$plugin_id"]="$stage"
  cp -a -- "$SOURCE_ROOT/$plugin_id/." "$stage/"
  [[ "$(tree_digest "$stage")" == "${SOURCE_DIGEST[$plugin_id]}" ]] || fail "Staged bytes or modes differ for $plugin_id"
  validate_plugin "$stage" || fail "Staged validation failed: $plugin_id"
done

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_root="$STATE_HOME/workbench/backups/omarchy-plugins/$stamp"

# Back up every adopted target before changing any target.
for plugin_id in "${PLUGIN_IDS[@]}"; do
  [[ "${ACTION[$plugin_id]}" == replace ]] || continue
  target_dir="$TARGET_ROOT/$plugin_id"
  [[ -d "$target_dir" && ! -L "$target_dir" ]] || fail "Target changed after preflight: $target_dir"
  [[ "$(tree_digest "$target_dir")" == "${CURRENT_DIGEST[$plugin_id]}" ]] || fail "Target changed after preflight: $target_dir"
  mkdir -p -- "$backup_root"
  cp -a -- "$target_dir" "$backup_root/$plugin_id"
  [[ "$(tree_digest "$backup_root/$plugin_id")" == "${CURRENT_DIGEST[$plugin_id]}" ]] || fail "Backup verification failed: $plugin_id"
done

for plugin_id in "${PLUGIN_IDS[@]}"; do
  action="${ACTION[$plugin_id]}"
  [[ "$action" != unchanged ]] || {
    printf '%-28s unchanged\n' "$plugin_id"
    continue
  }

  target_dir="$TARGET_ROOT/$plugin_id"
  stage="${STAGE[$plugin_id]}"

  if [[ "$action" == install ]]; then
    [[ ! -e "$target_dir" && ! -L "$target_dir" ]] || fail "Target appeared after preflight; refusing to overwrite: $target_dir"
    mv -T -n -- "$stage" "$target_dir"
    [[ ! -e "$stage" ]] || fail "Concurrent target creation prevented install: $target_dir"
  else
    [[ -d "$target_dir" && ! -L "$target_dir" ]] || fail "Target changed after backup: $target_dir"
    [[ "$(tree_digest "$target_dir")" == "${CURRENT_DIGEST[$plugin_id]}" ]] || fail "Target changed after backup: $target_dir"

    old_dir="$(mktemp -d "$TARGET_ROOT/.workbench-plugin-old.XXXXXX")"
    rmdir -- "$old_dir"
    mv -T -- "$target_dir" "$old_dir"
    if ! mv -T -n -- "$stage" "$target_dir" || [[ -e "$stage" ]]; then
      mv -T -- "$old_dir" "$target_dir" || true
      fail "Could not activate $plugin_id; prior target restored when possible"
    fi
    if [[ "$(tree_digest "$target_dir")" != "${SOURCE_DIGEST[$plugin_id]}" ]]; then
      failed_dir="$TARGET_ROOT/.workbench-plugin-failed.$plugin_id.$stamp"
      mv -T -- "$target_dir" "$failed_dir" || true
      mv -T -- "$old_dir" "$target_dir" || true
      fail "Post-copy verification failed for $plugin_id; prior target restored when possible"
    fi
    rm -rf -- "$old_dir"
  fi

  [[ "$(tree_digest "$target_dir")" == "${SOURCE_DIGEST[$plugin_id]}" ]] || fail "Post-copy verification failed: $plugin_id"
  validate_plugin "$target_dir" || fail "Installed validation failed: $plugin_id"
  STAGE["$plugin_id"]=""
  printf '%-28s restored\n' "$plugin_id"
done

trap - EXIT
cleanup_stages
if [[ -d "$backup_root" ]]; then
  printf 'Prior conflicting directories were backed up under: %s\n' "$backup_root"
fi
printf 'Restored four validated plugin directories. Shell settings and runtime IPC were untouched.\n'
