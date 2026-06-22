#!/bin/bash

# Workbench installation script
# This script creates symlinks from the home directory to the configuration files in this directory

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Workbench directory (assumes script is run from the workbench directory)
WORKBENCH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_SUBDIR="$WORKBENCH_DIR/dotfiles"

echo -e "${BLUE}Installing configuration files from $WORKBENCH_DIR${RESET}"

# Create symlinks for core configuration files
echo -e "${YELLOW}Creating symlinks for core configuration files...${RESET}"
ln -sf "$CONFIG_SUBDIR/.zshrc" "$HOME/.zshrc" && echo -e "${GREEN}✓ .zshrc${RESET}" || echo -e "${RED}✗ .zshrc${RESET}"
ln -sf "$CONFIG_SUBDIR/.aliases" "$HOME/.aliases" && echo -e "${GREEN}✓ .aliases${RESET}" || echo -e "${RED}✗ .aliases${RESET}"
ln -sf "$CONFIG_SUBDIR/.env" "$HOME/.env" && echo -e "${GREEN}✓ .env${RESET}" || echo -e "${RED}✗ .env${RESET}"
ln -sf "$CONFIG_SUBDIR/.fun" "$HOME/.fun" && echo -e "${GREEN}✓ .fun${RESET}" || echo -e "${RED}✗ .fun${RESET}"

# Install vtop themes
echo -e "${YELLOW}Installing vtop themes...${RESET}"
if command -v vtop &>/dev/null; then
  VTOP_DIR=$(npm root -g)/vtop
  if [ -d "$VTOP_DIR" ]; then
    mkdir -p "$VTOP_DIR/themes"
    for theme_file in "$CONFIG_SUBDIR/vtop/themes/"*.json; do
      if [ -f "$theme_file" ]; then
        theme_name=$(basename "$theme_file")
        cp -f "$theme_file" "$VTOP_DIR/themes/$theme_name" && echo -e "${GREEN}✓ vtop theme: $theme_name${RESET}" || echo -e "${RED}✗ vtop theme: $theme_name${RESET}"
      fi
    done
  else
    echo -e "${YELLOW}vtop not found in npm global modules, skipping theme installation${RESET}"
  fi
else
  echo -e "${YELLOW}vtop not installed, skipping theme installation${RESET}"
fi

# Create tmux local configuration symlink (Oh My Tmux theme)
# Note: ~/.tmux.conf should point to the Oh My Tmux framework, not this dotfile.
# Only .tmux.conf.local is managed here — it provides the Ember theme.
ln -sf "$CONFIG_SUBDIR/.tmux.conf.local" "$HOME/.tmux.conf.local" && echo -e "${GREEN}✓ .tmux.conf.local${RESET}" || echo -e "${RED}✗ .tmux.conf.local${RESET}"

# Setup Starship prompt configuration
echo -e "${YELLOW}Setting up Starship prompt...${RESET}"
mkdir -p "$HOME/.config"
ln -sf "$CONFIG_SUBDIR/starship.toml" "$HOME/.config/starship.toml" && echo -e "${GREEN}✓ starship.toml${RESET}" || echo -e "${RED}✗ starship.toml${RESET}"

# Setup Ghostty configuration
echo -e "${YELLOW}Setting up Ghostty configuration...${RESET}"
mkdir -p "$HOME/.config/ghostty/themes" "$HOME/.config/ghostty/shaders"
ln -sf "$CONFIG_SUBDIR/ghostty/config" "$HOME/.config/ghostty/config" && echo -e "${GREEN}✓ ghostty config${RESET}" || echo -e "${RED}✗ ghostty config${RESET}"
for shader_file in "$CONFIG_SUBDIR/ghostty/shaders/"*.glsl; do
  if [ -f "$shader_file" ]; then
    shader_name=$(basename "$shader_file")
    ln -sf "$shader_file" "$HOME/.config/ghostty/shaders/$shader_name" && echo -e "${GREEN}✓ ghostty shader: $shader_name${RESET}" || echo -e "${RED}✗ ghostty shader: $shader_name${RESET}"
  fi
done
for theme_file in "$CONFIG_SUBDIR/ghostty/themes/"*; do
  if [ -f "$theme_file" ]; then
    theme_name=$(basename "$theme_file")
    ln -sf "$theme_file" "$HOME/.config/ghostty/themes/$theme_name" && echo -e "${GREEN}✓ ghostty theme: $theme_name${RESET}" || echo -e "${RED}✗ ghostty theme: $theme_name${RESET}"
  fi
done

# Setup WezTerm configuration
echo -e "${YELLOW}Setting up WezTerm configuration...${RESET}"
mkdir -p "$HOME/.config/wezterm"
ln -sf "$CONFIG_SUBDIR/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua" && echo -e "${GREEN}✓ wezterm.lua${RESET}" || echo -e "${RED}✗ wezterm.lua${RESET}"

# Setup Zellij configuration
echo -e "${YELLOW}Setting up Zellij configuration...${RESET}"
mkdir -p "$HOME/.config/zellij"
ln -sf "$CONFIG_SUBDIR/zellij/config.kdl" "$HOME/.config/zellij/config.kdl" && echo -e "${GREEN}✓ zellij config${RESET}" || echo -e "${RED}✗ zellij config${RESET}"
mkdir -p "$HOME/.config/zellij/layouts" "$HOME/.config/zellij/plugins"
ln -sf "$CONFIG_SUBDIR/zellij/layouts/default.kdl" "$HOME/.config/zellij/layouts/default.kdl" && echo -e "${GREEN}✓ zellij default layout${RESET}" || echo -e "${RED}✗ zellij default layout${RESET}"
# Fetch zjstatus (status bar) + room (tab switcher) plugins if missing.
# Pinned to tagged releases for reproducibility: `latest` can pull a future
# build that breaks against the installed zellij (sessions are version-fragile).
# zjstatus v0.23.0 tracks zellij-tile 0.44.x (tested on 0.44.3). Bump when bumping zellij.
# File-download (not URL-load in the layout) is the upstream-recommended path —
# it sidesteps zellij#3479, where concurrent per-tab downloads corrupt the wasm.
# file|url|sha256 — a git tag is MUTABLE (can be re-pointed to a new binary);
# only the content hash is tamper-evident. Download to a temp path, verify the
# checksum, and ONLY THEN move into place, so a tampered/truncated file never
# lands. Re-capture hashes when bumping versions: shasum -a 256 *.wasm
for _zp in \
  "zjstatus.wasm|https://github.com/dj95/zjstatus/releases/download/v0.23.0/zjstatus.wasm|e006901223524239db618021e4cc5d17f82dc4bfae5432895ba41f03f13861ff" \
  "zjframes.wasm|https://github.com/dj95/zjstatus/releases/download/v0.23.0/zjframes.wasm|8d89e831bde195363faa5a810b04460a421006d37c9886ce9e255130fa93a085" \
  "room.wasm|https://github.com/rvcas/room/releases/download/v1.2.1/room.wasm|90b483a40b762468fb75862160587a05fbedcd5c13adcb3ed231f01bf9c072d1"; do
  _zf="${_zp%%|*}"; _rest="${_zp#*|}"; _zu="${_rest%%|*}"; _zh="${_rest##*|}"
  _dst="$HOME/.config/zellij/plugins/$_zf"
  if [ -f "$_dst" ]; then echo -e "${GREEN}✓ zellij plugin present: $_zf${RESET}"; continue; fi
  _tmp="$(mktemp)"
  if curl -fsSL "$_zu" -o "$_tmp" && echo "$_zh  $_tmp" | shasum -a 256 -c - >/dev/null 2>&1; then
    mv "$_tmp" "$_dst" && echo -e "${GREEN}✓ zellij plugin verified: $_zf${RESET}"
  else
    rm -f "$_tmp"; echo -e "${RED}✗ zellij plugin FAILED download/checksum: $_zf${RESET}"
  fi
done

# Seed the zjstatus plugin permission so a fresh session renders the bar
# immediately. Without it, zjstatus shows an (invisible, un-acceptable)
# "Allow? (y/n)" prompt inside the 1-row status bar — it can't be granted
# there, so the bar stays blank until you grant it some other way.
echo -e "${YELLOW}Seeding zjstatus permission grant...${RESET}"
case "$(uname -s)" in
  Darwin) ZJ_CACHE="$HOME/Library/Caches/org.Zellij-Contributors.Zellij" ;;
  *)      ZJ_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zellij" ;;
esac
mkdir -p "$ZJ_CACHE"
ZJ_PERMS="$ZJ_CACHE/permissions.kdl"
ZJ_PLUGIN="$HOME/.config/zellij/plugins/zjstatus.wasm"
if ! grep -qF "$ZJ_PLUGIN" "$ZJ_PERMS" 2>/dev/null; then
  printf '"%s" {\n    ReadApplicationState\n    ChangeApplicationState\n    RunCommands\n}\n' "$ZJ_PLUGIN" >> "$ZJ_PERMS"
  echo -e "${GREEN}✓ zjstatus permission seeded${RESET}"
else
  echo -e "${GREEN}✓ zjstatus permission already granted${RESET}"
fi

# Create Alacritty configuration directory and symlink
echo -e "${YELLOW}Setting up Alacritty configuration...${RESET}"
mkdir -p "$HOME/.config/alacritty"
# Backup existing alacritty config if it exists and isn't a symlink
if [ -e "$HOME/.config/alacritty/alacritty.toml" ] && [ ! -L "$HOME/.config/alacritty/alacritty.toml" ]; then
  backup_file="$HOME/.config/alacritty/alacritty.toml.bak.$(date +%Y%m%d%H%M%S)"
  echo -e "${YELLOW}Backing up $HOME/.config/alacritty/alacritty.toml to $backup_file${RESET}"
  mv "$HOME/.config/alacritty/alacritty.toml" "$backup_file"
elif [ -L "$HOME/.config/alacritty/alacritty.toml" ]; then
  # Remove existing symlink
  rm "$HOME/.config/alacritty/alacritty.toml"
fi
ln -sf "$CONFIG_SUBDIR/.alacritty.toml" "$HOME/.config/alacritty/alacritty.toml" && echo -e "${GREEN}✓ alacritty.toml${RESET}" || echo -e "${RED}✗ alacritty.toml${RESET}"

# Create backup of existing configurations if they exist
backup_if_exists() {
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    local backup="$1.bak.$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}Backing up $1 to $backup${RESET}"
    mv "$1" "$backup"
  fi
}

# Setup Git hooks + the secret scanner the pre-commit hook invokes.
echo -e "${YELLOW}Setting up Git hooks...${RESET}"
git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null
# gitleaks backs the pre-commit secret scan; without it the hook no-ops (warns).
command -v gitleaks >/dev/null 2>&1 || { command -v brew >/dev/null 2>&1 && brew install gitleaks; }
echo -e "${GREEN}✓ Git hooks${RESET}"

# WORKBENCH_DIR is exported directly in dotfiles/.zshrc (symlinked to ~/.zshrc),
# so there's nothing to append here. The old append-to-~/.zshrc block was a
# footgun: ~/.zshrc is a symlink to the tracked dotfile, so it wrote into the repo.

# Reload shell
echo -e "${GREEN}Installation complete!${RESET}"
echo -e "${YELLOW}To apply changes immediately, run:${RESET}"
echo -e "${BLUE}zsh -c \"source ~/.zshrc\"${RESET}"
