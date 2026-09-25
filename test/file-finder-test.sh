#!/usr/bin/env bash
# US-002 contracts for the file finder: secret stores and junk never reach the
# name index or text search, hidden folders do, a missing exclusion list fails
# closed, and text hits resolve to the right file.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FINDER="$ROOT_DIR/config/shared/file-finder/file-finder"
SCRATCH_PARENT="${TMPDIR:-$HOME/.cache/tmp}"
mkdir -p "$SCRATCH_PARENT"
TMP_ROOT="$(mktemp -d "$SCRATCH_PARENT/workbench-file-finder-test.XXXXXX")"
trap 'rm -rf -- "$TMP_ROOT"' EXIT

fail() {
  printf 'file-finder test: %s\n' "$*" >&2
  exit 1
}

export FILE_FINDER_ROOT="$TMP_ROOT/home"
# Keep actions away from the live clipboard and notifications: no reachable
# Wayland socket and no session bus.
export XDG_RUNTIME_DIR="$TMP_ROOT/runtime" WAYLAND_DISPLAY=file-finder-test-none
unset DISPLAY
export DBUS_SESSION_BUS_ADDRESS="unix:path=$TMP_ROOT/no-bus"
export FILE_FINDER_CACHE="$TMP_ROOT/index"

secrets=(
  .password-store/web/example.gpg
  .gnupg/private-keys-v1.d/key.key
  .local/share/keyrings/login.keyring
  .ssh/id_ed25519
  work/app/.env
  work/app/.env.production
  work/worker/.dev.vars
  .codex/auth.json
  agents/profile/home/.gnupg/pubring.kbx
  agents/profile/home/.codex/auth.json
)
junk=(
  work/app/node_modules/pkg/index.js
  work/app/.git/config
  .cache/thumbnails/a.png
)
visible=.local/share/probe/needle-probe.txt

for path in "${secrets[@]}" "${junk[@]}" "$visible"; do
  mkdir -p "$FILE_FINDER_ROOT/$(dirname "$path")"
  printf 'MARKER-7431 %s\n' "$path" > "$FILE_FINDER_ROOT/$path"
done

# Hostile names: a newline that would forge a ".env" row, and a colon name that
# old path:line:text parsing resolved to the excluded .env beside it.
printf 'MARKER-7431 forged\n' > "$FILE_FINDER_ROOT/work/app/notes"$'\n'".env"
printf 'intro\nbody\nneedle-colon\n' > "$FILE_FINDER_ROOT/work/app/.env:1:notes"
printf 'readme\n' > "$FILE_FINDER_ROOT/work/app/readme.md"
# Links: a folder link into ~/.ssh, innocent-looking links to keys inside and
# outside the home folder, and a link to an ordinary file outside it.
ln -s .ssh "$FILE_FINDER_ROOT/linked-keys"
ln -s .ssh/id_ed25519 "$FILE_FINDER_ROOT/innocent"
mkdir -p "$TMP_ROOT/vault/.ssh" "$TMP_ROOT/shared"
printf 'MARKER-7431 vault\n' > "$TMP_ROOT/vault/.ssh/id_rsa"
printf 'shared\n' > "$TMP_ROOT/shared/report.txt"
ln -s "$TMP_ROOT/vault/.ssh/id_rsa" "$FILE_FINDER_ROOT/vault-key"
ln -s "$TMP_ROOT/shared/report.txt" "$FILE_FINDER_ROOT/report-link"

"$FINDER" index
listing="$(zstd -dcq "$FILE_FINDER_CACHE"/paths-*.zst)"
text_hits="$("$FINDER" _text MARKER-7431)"

hit_paths="$(cut -f1 <<< "$text_hits")"
grep -qxF "$visible" <<< "$listing" || fail "hidden-folder file missing from the index"
grep -qxF "$visible" <<< "$hit_paths" || fail "hidden-folder file missing from text search"
[ "$("$FINDER" query needle-probe | head -n 1)" = "$visible" ] || fail "query did not rank the probe first"

for path in "${secrets[@]}" "${junk[@]}"; do
  if grep -qxF "$path" <<< "$listing"; then fail "index lists excluded $path"; fi
  if grep -qxF "$path" <<< "$hit_paths"; then fail "text search reads excluded $path"; fi
done
# Every other file holding the marker is a secret, junk, or a control-character name.
if grep -vqxF "$visible" <<< "$hit_paths"; then fail "text search read an excluded file: $hit_paths"; fi
for store in .password-store .gnupg .local/share/keyrings .ssh; do
  if grep -q "^$store" <<< "$listing"; then fail "index lists secret store $store"; fi
done
if grep -qxE '\.env|work/app/notes' <<< "$listing"; then fail "a newline in a file name forged a row"; fi
if grep -qF forged <<< "$text_hits"; then fail "text search listed a file name with a newline"; fi

preview() { FZF_PROMPT="$1" "$FINDER" _preview "$2"; }

row="$("$FINDER" _text needle-colon)"
[ "$row" = "work/app/.env:1:notes"$'\t'"3"$'\t'"needle-colon" ] || fail "unexpected text row: $row"
preview "text> " "$row" | grep -q needle-colon || fail "text-hit preview did not show the matching file"
if preview "text> " "$row" | grep -q MARKER-7431; then fail "text-hit preview read the excluded .env"; fi

folder="$(preview "files> " "work/app/")"
grep -qx readme.md <<< "$folder" || fail "folder preview hid an allowed file"
if grep -qE '^(\.env|\.env\.production|node_modules/|\.git/)$' <<< "$folder"; then
  fail "folder preview listed an excluded entry"
fi

for row in "work/app/.env" "linked-keys/id_ed25519" "innocent"; do
  if preview "files> " "$row" | grep -q MARKER-7431; then fail "preview of $row read a secret"; fi
done
for row in innocent vault-key; do
  if "$FINDER" _act copy-path "$row" 2> /dev/null; then fail "copy-path accepted $row, a link to a key"; fi
done
"$FINDER" _act copy-path report-link || fail "copy-path refused a link to an ordinary file"

# An index built under an older exclusion list is never read: after the list
# gains an entry, the finder stops listing it without waiting for a rebuild.
mkdir -p "$TMP_ROOT/copy"
cp "$FINDER" "$(dirname "$FINDER")/excludes" "$TMP_ROOT/copy/"
"$TMP_ROOT/copy/file-finder" index
grep -qxF "$visible" <<< "$("$TMP_ROOT/copy/file-finder" _names)" || fail "copied finder lost the probe"
printf 'needle-probe.txt\n' >> "$TMP_ROOT/copy/excludes"
if grep -qxF "$visible" <<< "$("$TMP_ROOT/copy/file-finder" _names)"; then
  fail "names came from an index built under an older exclusion list"
fi

# The finder refuses to walk or search without a valid shipped exclusion list.
mkdir -p "$TMP_ROOT/bare"
cp "$FINDER" "$TMP_ROOT/bare/file-finder"
rm -rf "$FILE_FINDER_CACHE"
if "$TMP_ROOT/bare/file-finder" index 2> /dev/null; then fail "index ran without an exclusion list"; fi
[ ! -e "$FILE_FINDER_CACHE" ] || fail "index was written without an exclusion list"
if "$TMP_ROOT/bare/file-finder" _text MARKER-7431 2> /dev/null; then
  fail "text search ran without an exclusion list"
fi
# fd silently ignores "name/" globs, so the parser must reject them.
printf '.ssh\nnode_modules/\n' > "$TMP_ROOT/bare/excludes"
if "$TMP_ROOT/bare/file-finder" index 2> /dev/null; then fail "index accepted an unsupported pattern"; fi

echo "file-finder test passed"
