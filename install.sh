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

backup_if_exists() {
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    local backup="$1.bak.$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}Backing up $1 to $backup${RESET}"
    mv "$1" "$backup"
  fi
}

install_core_dotfiles() {
  echo -e "${YELLOW}Creating symlinks for core configuration files...${RESET}"
  ln -sf "$CONFIG_SUBDIR/.zshrc" "$HOME/.zshrc" && echo -e "${GREEN}✓ .zshrc${RESET}" || echo -e "${RED}✗ .zshrc${RESET}"
  ln -sf "$CONFIG_SUBDIR/.zshenv" "$HOME/.zshenv" && echo -e "${GREEN}✓ .zshenv${RESET}" || echo -e "${RED}✗ .zshenv${RESET}"
  ln -sf "$CONFIG_SUBDIR/.aliases" "$HOME/.aliases" && echo -e "${GREEN}✓ .aliases${RESET}" || echo -e "${RED}✗ .aliases${RESET}"
  ln -sf "$CONFIG_SUBDIR/.env" "$HOME/.env" && echo -e "${GREEN}✓ .env${RESET}" || echo -e "${RED}✗ .env${RESET}"
  ln -sf "$CONFIG_SUBDIR/.fun" "$HOME/.fun" && echo -e "${GREEN}✓ .fun${RESET}" || echo -e "${RED}✗ .fun${RESET}"

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
}

install_tmux() {
  echo -e "${YELLOW}Setting up tmux configuration...${RESET}"
  # Note: ~/.tmux.conf should point to the Oh My Tmux framework, not this dotfile.
  # Only .tmux.conf.local is managed here — it provides the Ember theme.
  ln -sf "$CONFIG_SUBDIR/.tmux.conf.local" "$HOME/.tmux.conf.local" && echo -e "${GREEN}✓ .tmux.conf.local${RESET}" || echo -e "${RED}✗ .tmux.conf.local${RESET}"
}

install_starship() {
  echo -e "${YELLOW}Setting up Starship prompt...${RESET}"
  mkdir -p "$HOME/.config"
  ln -sf "$CONFIG_SUBDIR/starship.toml" "$HOME/.config/starship.toml" && echo -e "${GREEN}✓ starship.toml${RESET}" || echo -e "${RED}✗ starship.toml${RESET}"
}

install_ghostty() {
  echo -e "${YELLOW}Setting up Ghostty configuration...${RESET}"
  mkdir -p "$HOME/.config/ghostty/themes" "$HOME/.config/ghostty/shaders"
  ln -sf "$CONFIG_SUBDIR/ghostty/config" "$HOME/.config/ghostty/config" && echo -e "${GREEN}✓ ghostty config${RESET}" || echo -e "${RED}✗ ghostty config${RESET}"

  # macOS loads this native config after the XDG config. Ghostty's generated
  # template contains `theme =`, which resets the managed light/dark theme.
  # Remove only that empty reset; preserve any explicit user-owned override.
  if [ "$(uname -s)" = "Darwin" ]; then
    GHOSTTY_NATIVE_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    if [ -f "$GHOSTTY_NATIVE_CONFIG" ] && grep -Eq '^[[:space:]]*theme[[:space:]]*=[[:space:]]*$' "$GHOSTTY_NATIVE_CONFIG"; then
      sed -i '' -E '/^[[:space:]]*theme[[:space:]]*=[[:space:]]*$/d' "$GHOSTTY_NATIVE_CONFIG"
      echo -e "${GREEN}✓ removed Ghostty native empty theme override${RESET}"
    elif [ -f "$GHOSTTY_NATIVE_CONFIG" ] && grep -Eq '^[[:space:]]*theme[[:space:]]*=[[:space:]]*light:Rose Pine Dawn,dark:Rose Pine[[:space:]]*$' "$GHOSTTY_NATIVE_CONFIG"; then
      sed -i '' -E 's|^[[:space:]]*theme[[:space:]]*=.*$|theme = light:Ember Dawn,dark:Ember|' "$GHOSTTY_NATIVE_CONFIG"
      echo -e "${GREEN}✓ migrated Ghostty native Rose Pine theme override${RESET}"
    fi
  fi

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
}

install_nvim() {
  echo -e "${YELLOW}Setting up nvim configuration...${RESET}"
  mkdir -p "$HOME/.config/nvim"
  backup_if_exists "$HOME/.config/nvim/init.lua"
  ln -sf "$CONFIG_SUBDIR/nvim/init.lua" "$HOME/.config/nvim/init.lua" && echo -e "${GREEN}✓ nvim init.lua${RESET}" || echo -e "${RED}✗ nvim init.lua${RESET}"
}

install_herdr() {
  echo -e "${YELLOW}Setting up Herdr configuration...${RESET}"
  mkdir -p "$HOME/.config/herdr"
  ln -sf "$CONFIG_SUBDIR/herdr/config.toml" "$HOME/.config/herdr/config.toml" && echo -e "${GREEN}✓ herdr config${RESET}" || echo -e "${RED}✗ herdr config${RESET}"
}

install_codex_theme_sync() {
  # Setup Codex Ember themes and host appearance synchronization. The helper
  # only patches [tui].theme and refuses to replace unrelated Codex files.
  echo -e "${YELLOW}Setting up Codex theme synchronization...${RESET}"
  if [ -f "$HOME/.codex/config.toml" ] && [ -x "$WORKBENCH_DIR/bin/sync-system-theme" ]; then
    "$WORKBENCH_DIR/bin/sync-system-theme" --mode auto && echo -e "${GREEN}✓ Codex theme sync${RESET}" || echo -e "${RED}✗ Codex theme sync${RESET}"
  else
    echo -e "${YELLOW}Codex config not found, skipping live Codex theme sync${RESET}"
  fi
}

install_git_hooks() {
  echo -e "${YELLOW}Setting up Git hooks...${RESET}"
  git config core.hooksPath .githooks
  chmod +x .githooks/* 2>/dev/null
  echo -e "${GREEN}✓ Git hooks${RESET}"
}

install_gitleaks() {
  # gitleaks backs the pre-commit secret scan; without it the hook no-ops (warns).
  if command -v gitleaks >/dev/null 2>&1; then
    echo -e "${GREEN}✓ gitleaks${RESET}"
  elif command -v brew >/dev/null 2>&1; then
    if brew install gitleaks; then
      echo -e "${GREEN}✓ gitleaks${RESET}"
    else
      echo -e "${RED}WARNING: .githooks/pre-commit will no-op the gitleaks scan because gitleaks is not installed.${RESET}"
      echo -e "${YELLOW}Install gitleaks from https://github.com/gitleaks/gitleaks/releases${RESET}"
    fi
  else
    echo -e "${RED}WARNING: .githooks/pre-commit will no-op the gitleaks scan because gitleaks is not installed.${RESET}"
    echo -e "${YELLOW}Install gitleaks from https://github.com/gitleaks/gitleaks/releases${RESET}"
  fi
}

install_scheduler() {
  echo -e "${YELLOW}Setting up system theme scheduler...${RESET}"
  case "$(uname -s)" in
    Darwin)
      THEME_AGENT_LABEL="com.phaedrus.workbench.theme-sync"
      THEME_AGENT_PATH="$HOME/Library/LaunchAgents/$THEME_AGENT_LABEL.plist"
      THEME_AGENT_TEMPLATE="$WORKBENCH_DIR/launchd/$THEME_AGENT_LABEL.plist"
      mkdir -p "$HOME/Library/LaunchAgents" "$HOME/.config/workbench"
      THEME_AGENT_TEMP="$(mktemp "$HOME/Library/LaunchAgents/$THEME_AGENT_LABEL.plist.XXXXXX")"
      sed -e "s|__WORKBENCH_DIR__|$WORKBENCH_DIR|g" -e "s|__HOME__|$HOME|g" "$THEME_AGENT_TEMPLATE" > "$THEME_AGENT_TEMP"
      mv "$THEME_AGENT_TEMP" "$THEME_AGENT_PATH"
      if command -v launchctl >/dev/null 2>&1; then
        THEME_DOMAIN="gui/$(id -u)"
        launchctl bootout "$THEME_DOMAIN/$THEME_AGENT_LABEL" >/dev/null 2>&1 || true
        launchctl bootstrap "$THEME_DOMAIN" "$THEME_AGENT_PATH" >/dev/null 2>&1 && echo -e "${GREEN}✓ system theme LaunchAgent${RESET}" || echo -e "${YELLOW}LaunchAgent linked; load it with launchctl bootstrap if needed${RESET}"
      fi
      ;;
    Linux)
      mkdir -p "$HOME/.config/workbench" "$HOME/.config/systemd/user"
      SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
      for unit_file in \
        workbench-theme-sync.service \
        workbench-theme-sync.timer \
        workbench-dev-hygiene.service \
        workbench-dev-hygiene.timer; do
        unit_template="$WORKBENCH_DIR/systemd/$unit_file"
        unit_path="$SYSTEMD_USER_DIR/$unit_file"
        if sed -e "s|__WORKBENCH_DIR__|$WORKBENCH_DIR|g" -e "s|__HOME__|$HOME|g" "$unit_template" > "$unit_path"; then
          echo -e "${GREEN}✓ $unit_file${RESET}"
        else
          echo -e "${RED}✗ $unit_file${RESET}"
        fi
      done
      if command -v systemctl >/dev/null 2>&1; then
        if systemctl --user daemon-reload >/dev/null 2>&1; then
          echo -e "${GREEN}✓ systemd user units reloaded${RESET}"
        else
          echo -e "${YELLOW}systemd user units installed; daemon-reload failed${RESET}"
        fi
        if systemctl --user enable --now workbench-theme-sync.timer >/dev/null 2>&1; then
          echo -e "${GREEN}✓ workbench theme timer enabled${RESET}"
        else
          echo -e "${YELLOW}workbench theme timer installed; enable it with systemctl --user${RESET}"
        fi
        if systemctl --user enable --now workbench-dev-hygiene.timer >/dev/null 2>&1; then
          echo -e "${GREEN}✓ workbench hygiene timer enabled${RESET}"
        else
          echo -e "${YELLOW}workbench hygiene timer installed; enable it with systemctl --user${RESET}"
        fi
      else
        echo -e "${YELLOW}systemctl not found; systemd user timers were not enabled${RESET}"
      fi
      ;;
  esac
}

main() {
  echo -e "${BLUE}Installing configuration files from $WORKBENCH_DIR${RESET}"
  install_core_dotfiles
  install_tmux
  install_starship
  install_ghostty
  install_nvim
  install_herdr
  install_codex_theme_sync
  install_git_hooks
  install_gitleaks
  install_scheduler

  # WORKBENCH_DIR is exported directly in dotfiles/.zshrc (symlinked to ~/.zshrc),
  # so there's nothing to append here. The old append-to-~/.zshrc block was a
  # footgun: ~/.zshrc is a symlink to the tracked dotfile, so it wrote into the repo.

  echo -e "${GREEN}Installation complete!${RESET}"
  echo -e "${YELLOW}To apply changes immediately, run:${RESET}"
  echo -e "${BLUE}zsh -c \"source ~/.zshrc\"${RESET}"
}

main "$@"
