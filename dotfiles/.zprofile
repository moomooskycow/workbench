if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- 1Password ambient secret load (Agents vault, "fleet" service account) ---
# Resolve agent.env refs in-process with `op inject` and export the results, so
# every process in the terminal inherits the agent secrets. NO exec: if op
# fails for any reason (rate limit, network, bad ref) this falls through to a
# normal shell without secrets instead of killing the terminal. (The previous
# `exec op run ... zsh -l` design closed every new Ghostty tab the moment the
# service account was rate-limited — root-caused 2026-07-10.)
# Escape hatch: open a shell with OP_SKIP_AMBIENT=1 to bypass.
# Note: values are parsed line-wise; multi-line secrets are not supported here.
if [[ -z "${_OP_AMBIENT_LOADED:-}" && -z "${OP_SKIP_AMBIENT:-}" && -o interactive ]] && command -v op >/dev/null 2>&1; then
  __op_tok="$(security find-generic-password -a "$USER" -s op-agent -w 2>/dev/null)"
  if [[ -n "$__op_tok" ]] && \
     __op_env="$(grep -vE '^[[:space:]]*#' "$HOME/.config/op/agent.env" | OP_SERVICE_ACCOUNT_TOKEN="$__op_tok" op inject 2>/dev/null)"; then
    export _OP_AMBIENT_LOADED=1
    while IFS= read -r __op_line; do
      [[ "$__op_line" == [A-Za-z_]*=* ]] && export "${__op_line%%=*}=${__op_line#*=}"
    done <<< "$__op_env"
  fi
  unset __op_tok __op_env __op_line
fi

# mysql@8.0 is keg-only; ensure ARM client binaries win over any /usr/local remnants.
if [[ -d /opt/homebrew/opt/mysql@8.0/bin ]]; then
  export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
fi

export PATH="$HOME/.cargo/bin:$PATH"
export GOPATH=`go env GOPATH`
export PATH="$PATH:$GOPATH/bin"

# Login shells don't source ~/.zshrc, so do minimal PATH hygiene here too.
# Goal: keep Apple Silicon tooling first; keep /usr/local (Intel legacy) last.
typeset -U path

if [[ -d "$HOME/Library/pnpm" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  path=($PNPM_HOME $path)
fi

if [[ -d "$HOME/.yarn/bin" ]]; then
  path=($HOME/.yarn/bin $path)
fi

if [[ -d "$HOME/.config/yarn/global/node_modules/.bin" ]]; then
  path=($HOME/.config/yarn/global/node_modules/.bin $path)
fi

if [[ -d /opt/homebrew/opt/coreutils/libexec/gnubin ]]; then
  path=($path /opt/homebrew/opt/coreutils/libexec/gnubin)
fi

path=(${path:#/usr/local/bin} ${path:#/usr/local/sbin})
if [[ -d /usr/local/bin ]]; then
  path=($path /usr/local/bin)
fi
if [[ -d /usr/local/sbin ]]; then
  path=($path /usr/local/sbin)
fi

typeset -U path


# Added by Antigravity CLI installer
export PATH="/Users/phaedrus/.local/bin:$PATH"
