#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runtime_env="$ROOT_DIR/dotfiles/op/mint-agent.env"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "test-op-agent: $*" >&2
  exit 1
}

assert_agent_env() {
  OP_SERVICE_ACCOUNT_TOKEN="ambient-op-service-token" \
    OPENAI_API_KEY="ambient-openai-secret" \
    OPENAI_BASE_URL="https://api.openai.com/v1" \
    ANTHROPIC_API_KEY="ambient-anthropic-secret" \
    XAI_BASE_URL="https://api.x.ai/v1" \
    SHOULD_NOT_SURVIVE="ambient-test-secret" \
    MINT_RUNTIME_ENV_FILE="$runtime_env" \
    "$ROOT_DIR/bin/op-agent" bash -c '
      test -z "${OP_SERVICE_ACCOUNT_TOKEN:-}"
      test -z "${OPENAI_API_KEY:-}"
      test -z "${OPENAI_BASE_URL:-}"
      test -z "${ANTHROPIC_API_KEY:-}"
      test -z "${SHOULD_NOT_SURVIVE:-}"
      test "$CANARY_API_KEY" = "__mint.canary.default__"
      test "$CANARY_ENDPOINT" = "$MINT_BASE_URL/proxy/https/canary.mistystep.io"
      test "$XAI_BASE_URL" = "$MINT_BASE_URL/proxy/https/api.x.ai/v1"
      test "$DEEPGRAM_BASE_URL" = "$MINT_BASE_URL/proxy/https/api.deepgram.com/v1"
    '
}

test_shell_startup_does_not_load_service_token() {
  mkdir -p "$tmp/startup-bin"
  touch "$tmp/security-called"
  rm "$tmp/security-called"
  printf '%s\n' '#!/bin/sh' 'touch "${SECURITY_CALLED:?}"' 'exit 99' > "$tmp/startup-bin/security"
  chmod +x "$tmp/startup-bin/security"

  env -u OP_SERVICE_ACCOUNT_TOKEN -u OP_LOAD_DESKTOP_APP_SETTINGS -u OP_CACHE \
    SECURITY_CALLED="$tmp/security-called" \
    PATH="$tmp/startup-bin:$PATH" \
    zsh -f -c '
      source "$1"
      test -z "${OP_SERVICE_ACCOUNT_TOKEN:-}"
      test -z "${OP_LOAD_DESKTOP_APP_SETTINGS:-}"
      test -z "${OP_CACHE:-}"
    ' _ "$ROOT_DIR/dotfiles/.zshenv"
  test ! -e "$tmp/security-called" || fail ".zshenv called security"
}

make_agent_stubs() {
  mkdir -p "$tmp/bin" "$tmp/home"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'for name in OP_SERVICE_ACCOUNT_TOKEN OPENAI_API_KEY OPENAI_BASE_URL ANTHROPIC_API_KEY SHOULD_NOT_SURVIVE; do' \
    '  test -z "${!name:-}" || exit 70' \
    'done' \
    'test "$CANARY_API_KEY" = "__mint.canary.default__"' \
    'test "$XAI_BASE_URL" = "$MINT_BASE_URL/proxy/https/api.x.ai/v1"' \
    'printf "%s" "$(basename "$0")" >> "$HOME/entrypoints.log"' \
    'if [ "$#" -gt 0 ]; then printf " %s" "$@" >> "$HOME/entrypoints.log"; fi' \
    'printf "\n" >> "$HOME/entrypoints.log"' \
    > "$tmp/bin/agent-stub"
  chmod +x "$tmp/bin/agent-stub"
  for command in roster codex claude gemini opencode omp pictl; do
    ln -s agent-stub "$tmp/bin/$command"
  done
}

run_real_agent_aliases() {
  make_agent_stubs
  for entrypoint in c cx cxg db g o omp ompr i im; do
    env \
      HOME="$tmp/home" \
      PATH="$tmp/bin:$PATH" \
      OP_SERVICE_ACCOUNT_TOKEN="ambient-op-service-token" \
      OPENAI_API_KEY="ambient-openai-secret" \
      OPENAI_BASE_URL="https://api.openai.com/v1" \
      ANTHROPIC_API_KEY="ambient-anthropic-secret" \
      XAI_BASE_URL="https://api.x.ai/v1" \
      SHOULD_NOT_SURVIVE="ambient-test-secret" \
      MINT_RUNTIME_ENV_FILE="$runtime_env" \
      zsh -f -c '
        export WORKBENCH_DIR="$1"
        source "$WORKBENCH_DIR/dotfiles/op/op-agent.sh"
        source "$WORKBENCH_DIR/dotfiles/.aliases"
        eval "$2"
      ' _ "$ROOT_DIR" "$entrypoint"
  done

  expected="$tmp/expected-entrypoints.log"
  printf '%s\n' \
    'roster dispatch kaylee' \
    'roster dispatch amos' \
    'codex --profile glm --search --dangerously-bypass-approvals-and-sandbox' \
    "claude --dangerously-skip-permissions --append-system-prompt-file $tmp/home/Documents/daybook/.claude/system-prompt.md" \
    'gemini' \
    'opencode' \
    'roster dispatch urza' \
    'omp' \
    'pictl' \
    'pictl meta' \
    > "$expected"
  diff -u "$expected" "$tmp/home/entrypoints.log"
}

assert_agent_env
test_shell_startup_does_not_load_service_token
run_real_agent_aliases

echo "op-agent environment and real entrypoint isolation passed."
