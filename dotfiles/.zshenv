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

# Never load 1Password service credentials in shell startup. Human `op` use
# retains its normal Desktop integration and interactive authentication; agent
# entrypoints are isolated by `op-agent` and cannot inherit a vault token.
