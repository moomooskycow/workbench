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
- `roster/runtime.env` declares only value-free Mint routes under the explicit
  `ROSTER_CHILD_ENV_` prefix. Roster clears inherited state, strips that prefix
  for its child, and applies its own projection last. Powder uses the dedicated
  `__mint.powder.roster__` placeholder and Mint proxy origin; neither a raw
  Powder credential nor a credential resolver enters the child environment.
- `c`, `cx`, and `omp` launch raw Harnesses. `rc`, `rcx`, and `romp` opt into
  Kaylee, Amos, and Urza through Roster. No alias depends on a wrapper.
- Shell startup never loads `OP_SERVICE_ACCOUNT_TOKEN`; ordinary human `op`
  commands keep the CLI's interactive 1Password Desktop integration.
- OpenAI variables are intentionally absent from the shared agent runtime.
  Roster's image-generation references still contain direct vendor calls, so
  exporting even a Mint placeholder globally would imply a route they do not
  yet honor. Mint owns credential resolution; Roster owns process isolation.

## Remote Workflow

- `ph` - SSH to `phyrexia` with GitHub identity envs wired
- `ph "<command>"` - Run a single remote command with same identity wiring
- `phf` - Jump directly into remote `factory` tmux session (`attach` default)
- `phf up|status|kill|shell` - Manage factory session lifecycle on `phyrexia`
- `pht` - Short alias for `phf`
