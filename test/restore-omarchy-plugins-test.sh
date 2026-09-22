#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESTORE="$ROOT_DIR/scripts/restore-omarchy-plugins.sh"
SOURCE_ROOT="$ROOT_DIR/config/hosts/mirrodin/omarchy/plugins"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/workbench-plugin-restore-test.XXXXXX")"
trap 'rm -rf -- "$TMP_ROOT"' EXIT

fail() {
  printf 'restore test: %s\n' "$*" >&2
  exit 1
}

assert_trees_equal() {
  python3 - "$1" "$2" <<'PY'
from pathlib import Path
import stat
import sys

left, right = map(Path, sys.argv[1:])

def snapshot(root):
    if root.is_symlink() or not root.is_dir():
        raise SystemExit(f"not a real directory: {root}")
    result = {}
    for path in root.rglob("*"):
        if path.is_symlink():
            raise SystemExit(f"unexpected symlink: {path}")
        if path.is_dir():
            continue
        if not path.is_file():
            raise SystemExit(f"unsupported entry: {path}")
        result[path.relative_to(root).as_posix()] = (
            stat.S_IMODE(path.stat().st_mode),
            path.read_bytes(),
        )
    return result

if snapshot(left) != snapshot(right):
    raise SystemExit(f"trees differ: {left} != {right}")
PY
}

home="$TMP_ROOT/home"
config="$home/.config"
state="$home/.local/state"
bin="$TMP_ROOT/bin"
validator_log="$TMP_ROOT/validator.log"
mkdir -p "$home" "$bin"

cat > "$bin/omarchy-test" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
[[ "$#" -eq 3 && "$1" == plugin && "$2" == validate ]] || exit 64
plugin_dir="$3"
python3 - "$plugin_dir" <<'PY'
from pathlib import Path
import json
import sys

root = Path(sys.argv[1])
manifest = root / "manifest.json"
if root.is_symlink() or not root.is_dir() or not manifest.is_file():
    raise SystemExit(1)
for path in root.rglob("*"):
    if path.is_symlink():
        raise SystemExit(1)
data = json.loads(manifest.read_text(encoding="utf-8"))
if not str(data.get("id", "")).startswith("phaedrus."):
    raise SystemExit(1)
for entry in data.get("entryPoints", {}).values():
    if not (root / entry).is_file():
        raise SystemExit(1)
PY
printf '%s\n' "$plugin_dir" >> "$OMARCHY_STUB_LOG"
STUB
chmod 0755 "$bin/omarchy-test"

run_restore() {
  HOME="$home" \
  XDG_CONFIG_HOME="$config" \
  XDG_STATE_HOME="$state" \
  OMARCHY_BIN="$bin/omarchy-test" \
  OMARCHY_STUB_LOG="$validator_log" \
    "$RESTORE" "$@"
}

plugin_root="$config/omarchy/plugins"
plugin_ids=(
  phaedrus.headphone-battery
  phaedrus.idle
  phaedrus.lock
  phaedrus.menu
)

# Planning validates the source but must not create any target path.
run_restore > "$TMP_ROOT/plan.log"
[[ ! -e "$plugin_root" ]] || fail "plan created the plugin root"

# One conflicting target must fail the whole preflight before any named target
# is copied. An unrelated sibling is also preserved throughout the test.
mkdir -p "$plugin_root/phaedrus.lock" "$plugin_root/unowned.keep"
printf 'keep me\n' > "$plugin_root/phaedrus.lock/sentinel"
printf 'outside scope\n' > "$plugin_root/unowned.keep/value"
if run_restore --apply > "$TMP_ROOT/collision.log" 2>&1; then
  fail "unowned collision was accepted without --adopt"
fi
[[ "$(<"$plugin_root/phaedrus.lock/sentinel")" == "keep me" ]] || fail "collision target was overwritten"
[[ "$(<"$plugin_root/unowned.keep/value")" == "outside scope" ]] || fail "unowned sibling was overwritten"
for plugin_id in phaedrus.headphone-battery phaedrus.idle phaedrus.menu; do
  [[ ! -e "$plugin_root/$plugin_id" ]] || fail "preflight partially installed $plugin_id"
done
rm -rf -- "$plugin_root/phaedrus.lock"

# A fresh apply copies all four as real byte-and-mode-identical directories.
run_restore --apply > "$TMP_ROOT/install.log"
for plugin_id in "${plugin_ids[@]}"; do
  [[ -d "$plugin_root/$plugin_id" && ! -L "$plugin_root/$plugin_id" ]] || fail "missing real target for $plugin_id"
  assert_trees_equal "$SOURCE_ROOT/$plugin_id" "$plugin_root/$plugin_id"
done
[[ "$(stat -c '%a' "$plugin_root/phaedrus.headphone-battery/pair.sh")" == 755 ]] || fail "pair.sh mode changed"
[[ "$(stat -c '%a' "$plugin_root/phaedrus.headphone-battery/status.sh")" == 755 ]] || fail "status.sh mode changed"
[[ "$(<"$plugin_root/unowned.keep/value")" == "outside scope" ]] || fail "unowned sibling changed during install"

# Reapplying identical content is a no-op.
python3 - "$plugin_root" > "$TMP_ROOT/before.json" <<'PY'
from pathlib import Path
import hashlib
import json
import stat
import sys
root = Path(sys.argv[1])
out = {}
for path in sorted(root.rglob("*")):
    if path.is_file():
        out[path.relative_to(root).as_posix()] = [stat.S_IMODE(path.stat().st_mode), hashlib.sha256(path.read_bytes()).hexdigest()]
print(json.dumps(out, sort_keys=True))
PY
run_restore --apply > "$TMP_ROOT/noop.log"
python3 - "$plugin_root" > "$TMP_ROOT/after.json" <<'PY'
from pathlib import Path
import hashlib
import json
import stat
import sys
root = Path(sys.argv[1])
out = {}
for path in sorted(root.rglob("*")):
    if path.is_file():
        out[path.relative_to(root).as_posix()] = [stat.S_IMODE(path.stat().st_mode), hashlib.sha256(path.read_bytes()).hexdigest()]
print(json.dumps(out, sort_keys=True))
PY
cmp -s "$TMP_ROOT/before.json" "$TMP_ROOT/after.json" || fail "identical apply changed target content"

# A later local edit is refused and retained unless adoption is explicit.
tampered="$plugin_root/phaedrus.lock/Service.qml"
printf '\n// local unowned edit\n' >> "$tampered"
tampered_digest="$(sha256sum "$tampered")"
if run_restore --apply > "$TMP_ROOT/tamper-refusal.log" 2>&1; then
  fail "changed target was overwritten without --adopt"
fi
[[ "$(sha256sum "$tampered")" == "$tampered_digest" ]] || fail "refused target did not remain byte-identical"
[[ "$(<"$plugin_root/unowned.keep/value")" == "outside scope" ]] || fail "unowned sibling changed during refusal"

# Explicit adoption backs up the conflicting tree, then restores the snapshot.
run_restore --apply --adopt > "$TMP_ROOT/adopt.log"
assert_trees_equal "$SOURCE_ROOT/phaedrus.lock" "$plugin_root/phaedrus.lock"
shopt -s nullglob
backup_services=("$state"/workbench/backups/omarchy-plugins/*/phaedrus.lock/Service.qml)
[[ "${#backup_services[@]}" -eq 1 ]] || fail "expected one adopted lock backup"
python3 - "${backup_services[0]}" <<'PY'
from pathlib import Path
import sys
if not Path(sys.argv[1]).read_bytes().endswith(b"\n// local unowned edit\n"):
    raise SystemExit("adopted backup did not preserve the conflicting bytes")
PY
for plugin_id in "${plugin_ids[@]}"; do
  assert_trees_equal "$SOURCE_ROOT/$plugin_id" "$plugin_root/$plugin_id"
done
[[ "$(<"$plugin_root/unowned.keep/value")" == "outside scope" ]] || fail "unowned sibling changed during adoption"

python3 - "$validator_log" "${plugin_ids[@]}" <<'PY'
from pathlib import Path
import sys
lines = Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
ids = sys.argv[2:]
for plugin_id in ids:
    if not any(line.endswith("/" + plugin_id) for line in lines):
        raise SystemExit(f"target was never validated: {plugin_id}")
if not any("/.workbench-plugin-stage." in line for line in lines):
    raise SystemExit("no staged plugin validation was recorded")
PY

printf 'restore test passed: plan is read-only; collision refusal is all-or-nothing; four real directories copy byte-for-byte with modes; identical apply is a no-op; explicit adoption backs up conflicts; unowned sibling survives.\n'
