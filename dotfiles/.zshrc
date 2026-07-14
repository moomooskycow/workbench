# ===================================================================
# ZSH CONFIGURATION
# Modern shell configuration with enhanced productivity features
# ===================================================================

# macOS default soft limit is 256, too low for zellij + agent TUIs.
# SIP blocks launchctl limit maxfiles on 13.5+, so we set it here
# and let child processes (zellij, claude, codex, mosh) inherit.
# Hard cap is kern.maxfilesperproc (~138k); 65536 is safely under.
ulimit -n 65536

# --- HOMEBREW INTEGRATION ---
# Add Homebrew's zsh completions (Apple Silicon)
if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi

# Grok CLI completions — registered before compinit so they load in the single
# compinit pass below. Do NOT add a second compinit anywhere; it costs ~400ms.
if [[ -d $HOME/.grok/completions/zsh ]]; then
  fpath=($HOME/.grok/completions/zsh $fpath)
fi

# --- COMPLETION SYSTEM ---
# Single compinit pass (formerly done by oh-my-zsh). -C trusts the existing
# .zcompdump; rebuild it at most once a day.
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# --- CONFIGURATION SOURCING ---
# Load configurations in order: env vars → functions → aliases → secrets
source $HOME/.env                    # Environment variables and PATH
[ -f $HOME/.fun ] && source $HOME/.fun  # Utility functions
source $HOME/.aliases               # Command aliases and git helpers
# Agent entrypoints use the value-free Mint runtime and an empty inherited env.
[ -f $HOME/.config/op/op-agent.sh ] && source $HOME/.config/op/op-agent.sh

# --- HISTORY CONFIGURATION ---
# Enhanced history settings for better command recall
HISTFILE=~/.zsh_history
HISTSIZE=100000                    # Commands in memory
SAVEHIST=100000                    # Commands saved to file
setopt append_history               # Append to history file
setopt hist_ignore_all_dups        # Remove older duplicate entries
unsetopt hist_ignore_space          # Don't ignore commands starting with space
setopt hist_reduce_blanks           # Remove extra blanks
setopt hist_verify                  # Show command before executing from history
setopt inc_append_history           # Add commands immediately
setopt share_history                # Share history between sessions
setopt bang_hist                    # Enable ! history expansion
setopt extended_history             # Timestamp each history entry
setopt hist_find_no_dups            # Skip dups when searching history

# --- EXTERNAL TOOL INTEGRATIONS ---
# Initialize various development and productivity tools

# TheFuck - correct previous command typos
if command -v thefuck >/dev/null 2>&1; then
  fuck() {
    eval "$(thefuck --alias)" && fuck
  }
fi

# Zoxide - smart directory navigation (cd replacement)
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# Mise - universal version manager (replaced asdf 2026-06; reads .tool-versions)
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

# FZF - fuzzy finder with ripgrep integration
if type rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden'
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# --- ADDITIONAL PATH EXPORTS ---
# Supplementary PATH additions (main PATH config in .env)
export PATH="$HOME/bin:$PATH"

# --- CLOUD SDK INTEGRATIONS ---
# Google Cloud SDK
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/path.zsh.inc"
fi
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# --- PACKAGE MANAGER INTEGRATIONS ---
# PNPM integration
export PNPM_HOME="/Users/phaedrus/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Deno runtime environment
. "/Users/phaedrus/.deno/env"

# --- PROMPT INITIALIZATION ---
# Starship - modern cross-shell prompt
if [[ "$TERM" != "dumb" ]] && command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# --- PROJECT-SPECIFIC EXPORTS ---
export WORKBENCH_DIR="/Users/phaedrus/Development/workbench"

# QMD (daybook semantic search) native-runtime pin. better-sqlite3 is compiled
# for Node 22 (NODE_MODULE_VERSION 127); the qmd launcher otherwise auto-selects
# a newer mise/homebrew Node (24/26 → modules 137/147) that cannot dlopen it.
# The `22` symlink tracks the latest 22.x, which is ABI-stable at 127.
export QMD_NODE="$HOME/.local/share/mise/installs/node/22/bin/node"

# opencode
export PATH=/Users/phaedrus/.opencode/bin:$PATH


# Added by Antigravity
export PATH="/Users/phaedrus/.antigravity/antigravity/bin:$PATH"

# --- PATH HYGIENE ---
# Keep npm-global last; de-dupe entries. (mise activate manages tool paths.)
typeset -U path
path=(${path:#$HOME/.npm-global/bin})
if [[ -d $HOME/.npm-global/bin ]]; then
  path=($path $HOME/.npm-global/bin)
fi
typeset -U path

# --- DAYBOOK QUOTE OF SESSION ---
# Deck-shuffled quote at the top of each interactive shell. The guard prevents
# re-printing on subshells or `exec zsh`.
if [[ -o interactive && -z "$QUOTE_SHOWN" ]]; then
  export QUOTE_SHOWN=1
  # Hard timeout so a misbehaving quote path (a stalled tool, or an
  # iCloud-evicted quotes dir) can never block shell startup. Falls back to a
  # direct call if `timeout` is unavailable.
  if (( $+commands[timeout] )); then
    timeout 2 "$HOME/Documents/daybook/scripts/quote-session.sh" 2>/dev/null || true
  else
    "$HOME/Documents/daybook/scripts/quote-session.sh" 2>/dev/null || true
  fi
fi

# bun
[ -s "/Users/phaedrus/.bun/_bun" ] && source "/Users/phaedrus/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# direnv - auto-load .envrc per directory
eval "$(direnv hook zsh)"

# Pop kitty keyboard protocol if a TUI app left it enabled (Claude Code bug)
__reset_kitty_keyboard_protocol() { printf '\e[<u' 2>/dev/null; }
precmd_functions+=(__reset_kitty_keyboard_protocol)


# Added by Antigravity CLI installer
export PATH="/Users/phaedrus/.local/bin:$PATH"

# Added by Antigravity IDE
export PATH="/Users/phaedrus/.antigravity-ide/antigravity-ide/bin:$PATH"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
# fpath + compinit intentionally removed. Grok completions are registered in the
# Homebrew/completions block near the top so the single compinit pass picks them
# up. Do NOT re-add `compinit` here — a second pass costs ~400ms every shell.
# <<< grok installer <<<

# --- SHELL PLUGINS ---
# Brew-installed (formerly oh-my-zsh plugins). Syntax highlighting must be
# sourced last — it wraps the line editor and anything loaded after it is
# not highlighted.
[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- FINAL PATH DEDUP ---
# Installer-appended PATH lines (Antigravity, grok, bun, deno, opencode) land
# after the earlier dedup near line 129, so collapse duplicates one last time.
typeset -U path
