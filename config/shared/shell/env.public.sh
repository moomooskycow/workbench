# PUBLIC, TRACKED ENVIRONMENT CONFIGURATION
#
# Safe to publish: PATH entries, locale settings, and tool homes.
# Credentials belong in env.local.private.sh.

export EDITOR="nvim"
export VISUAL="nvim"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export DEVELOPMENT="$HOME/development"
export DAYBOOK_DIR="$DEVELOPMENT/moomooskycow/daybook"
export DAYBOOK_QUOTES_DIR="$DAYBOOK_DIR/Quotes"

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/development/moomooskycow/workbench/bin:$PATH"

export GOPATH="$HOME/go"
export GOBIN="$HOME/go/bin"
export PATH="$PATH:$GOBIN"

if command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden'
fi
