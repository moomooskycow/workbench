#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runtime_env="$ROOT_DIR/dotfiles/roster/runtime.env"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "test-roster-runtime: $*" >&2
  exit 1
}

mkdir -p "$tmp/home/.config/roster" "$tmp/bin"
ln -s "$runtime_env" "$tmp/home/.config/roster/runtime.env"
touch "$tmp/security-called"
rm "$tmp/security-called"
printf '%s\n' '#!/bin/sh' 'touch "${SECURITY_CALLED:?}"' 'exit 99' > "$tmp/bin/security"
chmod +x "$tmp/bin/security"

env -u OP_SERVICE_ACCOUNT_TOKEN -u OP_LOAD_DESKTOP_APP_SETTINGS -u OP_CACHE -u MINT_BASE_URL \
  -u POWDER_API_BASE_URL -u POWDER_API_KEY \
  HOME="$tmp/home" SECURITY_CALLED="$tmp/security-called" PATH="$tmp/bin:$PATH" \
  zsh -f -c '
    set -e
    source "$1"
    test -z "${OP_SERVICE_ACCOUNT_TOKEN:-}"
    test -z "${OP_LOAD_DESKTOP_APP_SETTINGS:-}"
    test -z "${OP_CACHE:-}"
    test -z "${MINT_BASE_URL:-}"
    test -z "${POWDER_API_BASE_URL:-}"
    test -z "${POWDER_API_KEY:-}"
    test "$ROSTER_CHILD_ENV_CANARY_API_KEY" = "__mint.canary.default__"
    test "$ROSTER_CHILD_ENV_CANARY_ENDPOINT" = "$ROSTER_CHILD_ENV_MINT_BASE_URL/proxy/https/canary.mistystep.io"
    test "$ROSTER_CHILD_ENV_POWDER_API_BASE_URL" = "$ROSTER_CHILD_ENV_MINT_BASE_URL/proxy/https/sanctum.tail5f5eb4.ts.net:10001"
    test "$ROSTER_CHILD_ENV_POWDER_API_KEY" = "__mint.powder.roster__"
    test "$ROSTER_CHILD_ENV_XAI_BASE_URL" = "$ROSTER_CHILD_ENV_MINT_BASE_URL/proxy/https/api.x.ai/v1"
    test "$ROSTER_CHILD_ENV_DEEPGRAM_BASE_URL" = "$ROSTER_CHILD_ENV_MINT_BASE_URL/proxy/https/api.deepgram.com/v1"
  ' _ "$ROOT_DIR/dotfiles/.zshenv"
test ! -e "$tmp/security-called" || fail ".zshenv called security"

printf '%s\n' '#!/usr/bin/env bash' 'printf "%s" "$(basename "$0")" >> "$HOME/entrypoints.log"' 'if [ "$#" -gt 0 ]; then printf " %s" "$@" >> "$HOME/entrypoints.log"; fi' 'printf "\n" >> "$HOME/entrypoints.log"' > "$tmp/bin/agent-stub"
chmod +x "$tmp/bin/agent-stub"
for command in roster codex claude gemini opencode omp pictl; do
  ln -s agent-stub "$tmp/bin/$command"
done

for entrypoint in c cx cxg db g o omp ompr i im rc rcx romp; do
  env HOME="$tmp/home" PATH="$tmp/bin:$PATH" zsh -f -c '
    source "$1"
    eval "$2"
  ' _ "$ROOT_DIR/dotfiles/.aliases" "$entrypoint"
done

printf '%s\n' \
  'claude --dangerously-skip-permissions' \
  'codex --search --dangerously-bypass-approvals-and-sandbox' \
  'codex --profile glm --search --dangerously-bypass-approvals-and-sandbox' \
  "claude --dangerously-skip-permissions --append-system-prompt-file $tmp/home/Documents/daybook/.claude/system-prompt.md" \
  'gemini' \
  'opencode' \
  'omp' \
  'omp' \
  'pictl' \
  'pictl meta' \
  'roster dispatch --default claude' \
  'roster dispatch --default codex' \
  'roster dispatch --default omp' \
  > "$tmp/expected-entrypoints.log"
diff -u "$tmp/expected-entrypoints.log" "$tmp/home/entrypoints.log"

echo "Roster runtime declaration and direct entrypoints passed."
