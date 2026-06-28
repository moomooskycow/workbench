# workbench

Personal configuration repository for development environment setup, terminal preferences, project registry docs, and utility scripts.

## Features

- Shell configs (`.zshrc`, `.aliases`, `.env`)
- Terminal configs for Alacritty, Ghostty, WezTerm, Zellij, tmux, and Starship
- Project registry docs and naming notes
- Utility scripts for local development workflows
- Git hooks and automated quality checks

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


## Structure

- `/dotfiles/` - Shell configs (`.zshrc`, `.aliases`, `.env`)
- `/bin/` - Local utility scripts
- `/docs/` - Project registry, guides, and professional docs
- `/scripts/` - System maintenance and setup



## License

MIT
