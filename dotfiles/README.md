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
- `op-agent` starts agents with an allowlisted environment from
  `op/mint-agent.env`; credential variables contain only Mint placeholders and
  their clients are pinned to Mint proxy URLs. It never resolves
  `~/.config/op/agent.env`.
- Primary agent aliases (`c`, `cx`, `cxg`, `db`, `g`, `o`, `omp`, `ompr`,
  `i`, and `im`) enter through `op-agent`. Shell startup never loads
  `OP_SERVICE_ACCOUNT_TOKEN`; ordinary human `op` commands keep the CLI's
  interactive 1Password Desktop integration.
- OpenAI variables are intentionally absent from the shared agent runtime.
  Roster's image-generation references still contain direct vendor calls, so
  exporting even a Mint placeholder globally would imply a route they do not
  yet honor.

## Remote Workflow

- `ph` - SSH to `phyrexia` with GitHub identity envs wired
- `ph "<command>"` - Run a single remote command with same identity wiring
- `phf` - Jump directly into remote `factory` tmux session (`attach` default)
- `phf up|status|kill|shell` - Manage factory session lifecycle on `phyrexia`
- `pht` - Short alias for `phf`
