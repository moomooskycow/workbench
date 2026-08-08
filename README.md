# workbench

Public, version-controlled workstation configuration with explicit shared,
Mirrodin, and Serenity layers.

## Profiles

- `config/shared/`: public-safe shell modules and cross-host application assets.
- `config/hosts/serenity/`: the lightweight macOS daily-driver profile.
- `config/hosts/mirrodin/`: the Linux engineering-workstation profile.
- `~/.config/workbench/env.local.private.zsh`: optional untracked secrets and
  machine-local overrides. It is never stored here.

Each host manifest is the source of truth for installed paths. Preview first:

```bash
./install.sh --profile serenity
./install.sh --profile serenity --apply --adopt
```

Applying creates an immutable release under `~/.local/share/workbench/releases`
and backs up adopted files under `~/.local/state/workbench/backups`. It never
links live configuration directly into the mutable checkout.

## Agent message board

Agents keep a shared message board in the daybook at `daybook/meta/agents-board/`.
It is where agents talk to themselves, to other agents, and to their future
selves — post operational knowledge there (machine access, gotchas, handoffs)
and read it before working. Charter: `meta/agents-board/README.md`. This repo
must not hold secrets; the board references machine-local stores (`~/.secrets`,
Mint) by name only.

## Secret scanning

TruffleHog is the standard scanner. The repository hooks check staged content
and outgoing commits, fail closed when scanning fails, and suppress raw values.
To safely layer these checks in front of existing hooks across local repositories:

```bash
scripts/manage-trufflehog-hooks --root ~/Development
scripts/manage-trufflehog-hooks --root ~/Development --apply
```

The manager records each repository's prior `core.hooksPath`, chains its existing
hooks, deduplicates linked worktrees, and supports `--uninstall`. Do not set a
global `core.hooksPath`; that silently bypasses repository-owned hook systems.

## Quality gate

```bash
scripts/check.sh
```

This validates shell syntax, ShellCheck error-level findings, profile manifests,
and the full Git history with TruffleHog.

## Appearance

Serenity uses a calm, highly legible Flexoki light/dark Ghostty pairing and a
cool-blue prompt. Mirrodin uses Ember/Ember Dawn and a warmer copper prompt, so
remote context is visible without loud banners. `bin/sync-system-theme` handles
the broader appearance synchronization where installed.
