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

- Modular organization with clear sections
- Environment-aware setup
- POSIX-compatible syntax
- Security-conscious (no secrets in configs)
- Shell startup carries no harness-specific credential projection. Mint owns
  credential resolution, and repository-local launch contracts declare each
  agent's tools, skills, MCP servers, model policy, and execution boundary.
- `c`, `cx`, and `omp` launch their stock harnesses. `omp-lean`, `omp-design`,
  `omp-ops`, and `omp-research` select explicit OMP configuration overlays.
- Shell startup never loads `OP_SERVICE_ACCOUNT_TOKEN`; ordinary human `op`
  commands keep the CLI's interactive 1Password Desktop integration.
- OpenAI variables are intentionally absent from the shared agent runtime.

## Remote Workflow

- `ph` - SSH to `phyrexia` with GitHub identity envs wired
- `ph "<command>"` - Run a single remote command with same identity wiring
- `phf` - Jump directly into remote `factory` tmux session (`attach` default)
- `phf up|status|kill|shell` - Manage factory session lifecycle on `phyrexia`
- `pht` - Short alias for `phf`
