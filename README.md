# workbench

Personal configuration repository for development environment setup, terminal preferences, project registry docs, and utility scripts.

## Features

- Shell configs (`.zshenv`, `.zshrc`, `.aliases`, `.env`)
- Terminal configs for Alacritty, Ghostty, WezTerm, Zellij, tmux, and Starship
- Project registry docs and naming notes
- Utility scripts for local development workflows
- Git hooks and automated quality checks
- Ember light/dark synchronization across Ghostty, Herdr, Codex, nen, nvim, Alacritty, WezTerm

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

One aesthetic: **Ember** (dark charcoal + copper) / **Ember Dawn** (parchment).

| Surface | Dark | Light |
| --- | --- | --- |
| Ghostty | Ember | Ember Dawn |
| Herdr | `terminal` + copper accent | same (rides Ghostty ANSI) |
| Codex syntax | `ember.tmTheme` | `ember-dawn.tmTheme` |
| nen (pi coat) | `nen-moon` | `nen-day` |
| OMP / Hatchet | `dark-ember-ink` | `light-ember` |
| nvim | `ember` (dark) | `ember` (light) |
| Alacritty | `alacritty-themes/dark.toml` | `light.toml` |
| WezTerm | Ember scheme | Ember Dawn scheme |
| Starship | Ghostty ANSI (inherits) | same |

Claude Code uses its `auto` theme. Herdr keeps transparent chrome
(`panel_bg = reset`) and agent-aware sidebars. On macOS the installer also
removes Ghostty's generated empty `theme =` override. `bin/sync-system-theme`
updates Codex `[tui].theme` and links both Ember themes under `~/.codex/themes`.
Starship resolves prompt colors through Ghostty's ANSI palette.
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
