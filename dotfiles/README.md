# Dotfiles

Shell configuration files for consistent development environment.

## Files

- `.zshrc` - Main shell configuration
- `.aliases` - Command shortcuts  
- `.env` - Environment variables
- `.fun` - Shell utility functions

## Installation

Automatically symlinked by `install.sh`:
```bash
cd ~/Development/workbench && ./install.sh
```

## Configuration

- Modular organization: `.env` (PATH and tool homes), `.zshrc` (interactive shell), `.aliases`, `.fun`
- Shell startup carries no harness-specific credential projection. Mint owns credential resolution.
- Default agent launcher alias is `o` → `omp`
- Shell startup never loads `OP_SERVICE_ACCOUNT_TOKEN`; ordinary human `op` commands keep the CLI Desktop integration
- OpenAI variables are intentionally absent from the shared agent runtime
