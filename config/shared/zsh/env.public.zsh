# PUBLIC, TRACKED ENVIRONMENT CONFIGURATION
#
# This file is intentionally safe to publish. It may contain PATH entries,
# locale settings, and tool homes only. Credentials, tokens, private endpoints,
# and machine identity belong in ~/.config/workbench/env.local.private.zsh,
# which workbench never creates or tracks.

# --- CORE SYSTEM SETTINGS ---
# Primary editor and locale settings
export EDITOR="nvim"                                          # Default text editor
export LANG=en_US.UTF-8                                       # System language
export LC_ALL=en_US.UTF-8                                     # Locale settings

# --- DEVELOPMENT DIRECTORIES ---
# Standard development environment paths
export DEVELOPMENT="$HOME/Development"                        # Main development directory
export DAYBOOK_DIR="$DEVELOPMENT/moomooskycow/daybook"
export DAYBOOK_QUOTES_DIR="$DAYBOOK_DIR/Quotes"
# --- CORE PATH CONFIGURATION ---
# Essential binary directories (avoid duplicates with main PATH below)
export PATH="$HOME/.cargo/bin:$PATH"                          # Rust cargo binaries
export PATH="$HOME/.local/bin:$PATH"                          # Local user binaries

# --- PROGRAMMING LANGUAGE ENVIRONMENTS ---
# Language-specific configurations and PATH additions

# Go development environment
export GOPATH="$HOME/go"                                      # Go workspace
export GOBIN="$HOME/go/bin"                                   # Go binary directory
export PATH="$PATH:/usr/local/go/bin:$GOBIN"                  # Go compiler and tools

# --- PACKAGE MANAGERS & TOOLS ---
# Configuration for various package managers and development tools

# Node.js package managers
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"  # Yarn global packages

# --- VISUAL & UI CONFIGURATION ---
# Terminal colors and appearance
# Keep Vivid's semantic colors, but do not turn file types into heavy text.
if command -v vivid >/dev/null 2>&1; then
  export LS_COLORS="$(vivid generate solarized-light | sed -E 's/(^|=|:)1;/\1/g')"
fi

# --- SEARCH & NAVIGATION TOOLS ---
# FZF fuzzy finder with ripgrep integration
if type rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden'           # Use ripgrep for file search
fi

# --- PROJECT-SPECIFIC PATHS ---
export PATH="$PATH:$DEVELOPMENT/workbench/bin"                    # Workbench project utilities
