# workbench

Personal configuration repository for development environment setup, terminal preferences, project registry docs, and utility scripts.

## Features

- Shell configs (`.zshenv`, `.zshrc`, `.aliases`, `.env`)
- Terminal configs for Alacritty, Ghostty, WezTerm, Zellij, tmux, and Starship
- Project registry docs and naming notes
- Utility scripts for local development workflows
- Git hooks and automated quality checks
- Rose Pine light/dark synchronization for Codex, Claude Code, Herdr, and Ghostty

## Quality Gate

Run the repo-owned gate before opening or merging a change:

```bash
scripts/check.sh
```

The gate validates shell syntax for the tracked shell entrypoints and runs
ShellCheck at error severity. GitHub Actions only installs ShellCheck and calls
this same script.

## Installation

```bash
git clone https://github.com/phrazzld/workbench.git ~/Development/workbench
cd ~/Development/workbench
./install.sh
```

## Agent appearance

The supported automatic path follows the macOS appearance setting: Claude Code
uses its `auto` theme, Herdr uses the Rose Pine/Rose Pine Dawn pair with
`auto_switch`, and Ghostty already uses its native system theme pair. Codex's
custom TUI themes live under `dotfiles/codex/themes`; `bin/sync-system-theme`
updates only `[tui].theme` and keeps both themes linked under `~/.codex/themes`.
The installer registers a small LaunchAgent that checks the host appearance
once a minute. Preview either state without changing anything with:

```bash
bin/sync-system-theme --mode light --dry-run
bin/sync-system-theme --mode dark --dry-run
```


## Structure

- `/dotfiles/` - Shell configs (`.zshenv`, `.zshrc`, `.aliases`, `.env`)
- `/bin/` - Local utility scripts
- `/docs/` - Project registry, guides, and professional docs
- `/scripts/` - System maintenance and setup



## License

MIT
