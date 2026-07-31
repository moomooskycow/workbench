# Minimal PATH bootstrap for non-interactive zsh shells launched by GUI apps.
# Keep this file side-effect free: no prompts, evals, starship, or slow commands.

typeset -gaU path

for _codex_path_dir in \
  "$HOME/.bun/bin" \
  "$HOME/.npm-global/bin" \
  "$HOME/.opencode/bin" \
  "$HOME/Library/pnpm" \
  "/opt/homebrew/sbin" \
  "/opt/homebrew/bin" \
  "$HOME/.cargo/bin" \
  "$HOME/.local/bin"
do
  [[ -d "$_codex_path_dir" ]] && path=("$_codex_path_dir" $path)
done

unset _codex_path_dir
export PATH


# Retired Roster child-environment names must not leak from stale GUI parents.
unset ROSTER_CHILD_ENV_CANARY_API_KEY ROSTER_CHILD_ENV_CANARY_ENDPOINT \
  ROSTER_CHILD_ENV_DEEPGRAM_BASE_URL ROSTER_CHILD_ENV_MINT_BASE_URL \
  ROSTER_CHILD_ENV_POWDER_API_BASE_URL ROSTER_CHILD_ENV_POWDER_API_KEY \
  ROSTER_CHILD_ENV_XAI_BASE_URL
