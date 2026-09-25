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

To install one manifest item without relinking the rest, add `--only ID` (for
example `--only fcitx5-profile`). It leaves other targets and the
current-release pointer untouched.

fcitx5 (US-003) re-encodes keys for input-method clients such as Wayland
Chromium through its own virtual keyboard, so `config/shared/fcitx5/profile`
keeps its engine at `keyboard-us-dvorak`, matching Hyprland's layout 0. fcitx5
reads the profile only at startup; `fcitx5-remote -r` does not reload it. After
applying, restart `omarchy-fcitx5.service` or set the running group over DBus:

```bash
busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 \
  SetInputMethodGroupInfo 'ssa(ss)' Default us-dvorak 1 keyboard-us-dvorak ""
fcitx5-remote -n  # keyboard-us-dvorak
```

fcitx5 saves the profile through the release link with identical bytes;
`scripts/omarchy-drift.sh` flags any other write-through. Hyprland's layout 1
(QWERTY) switches only keys that bypass fcitx5.

Source edits do not authorize applying profiles, granting privileges, activating
timers, or administering a host. Those operations require explicit task scope.

## Standalone applications (Mirrodin)

The host manifest owns files deployed from immutable Workbench releases. Applications
whose own installers manage several runtime artifacts stay outside that manifest;
recording them here establishes provenance without making Workbench their installer.

### AI Usage

- **Source owner:** [`misty-step/ai-usage`](https://github.com/misty-step/ai-usage)
  (private; authenticated repository access is required).
- **Install owner:** that repository's `install.sh`. It owns the validated copied
  Omarchy plugin directory, CLI wrapper, desktop launcher, and user collector units.
  Workbench does not copy or symlink those artifacts; Omarchy rejects a symlinked
  plugin directory during package validation.
- **Fresh checkout:**

  ```bash
  gh repo clone misty-step/ai-usage "$HOME/development/misty-step/ai-usage"
  ```

- **Install / full reinstall from the checkout:**

  ```bash
  cd "$HOME/development/misty-step/ai-usage"
  tests/run.sh
  ./install.sh install
  ```

  For an app-only repair that must preserve the existing collector timer, run
  `./install.sh install-app`. The repository documents the matching uninstall and
  rollback commands.

## Agent message board

The private Daybook board at `daybook/meta/agents-board/` can supply operational
context or handoffs when an authorized task needs it. It is not a prerequisite
for public source work. Keep private board contents out of this repository;
refer to secret stores by name, never by value.

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

Omarchy bindings (US-001) load an optional `~/.config/hypr/bindings.local.lua`
last. Keep host-only shortcuts and private application paths there, rather than
in the public `config/shared/hypr/bindings.lua`. Workbench never installs or
overwrites the local file; a present file must be valid Lua for Hyprland reload.

## File finder (Mirrodin)

Super+Ctrl+/ opens a floating fuzzy finder over the whole home folder,
hidden folders included (US-002). Omarchy 4 has no home-wide file search: it
replaced Walker and Elephant, whose file indexer caused disk-I/O storms, with a
menu that searches applications and commands, and `omarchy menu file` only
lists chosen folders by extension, skipping hidden ones.

| Key | Action |
| --- | --- |
| type | fuzzy-match file and folder names |
| Ctrl+T | switch between name search and text search (ripgrep) |
| Enter | open with the default application |
| Ctrl+O | show in the file manager |
| Ctrl+Y | copy the absolute path (paste it into an upload dialog's location field) |
| Ctrl+F | copy the file itself as a `text/uri-list`, for pasting into browsers and chat apps |

`file-finder query TEXT` prints the best matches from a shell.

`config/shared/file-finder/excludes` is the single exclusion list: secret
stores (password store, `~/.gnupg`, `~/.ssh`, keyrings, `.env` and
`.dev.vars` files, and named credential files, at any depth), version-control
internals, dependency folders, caches, and package stores. fd and ripgrep
apply it to the walk and text search, and every preview, folder listing, and
action re-checks the selected path against it, refusing paths under a
symlinked folder and links into excluded places. File names containing
control characters are never listed. The script reads the list beside its own
release copy, accepts only bare names, `/anchored/paths`, and `**/any/depth`
paths, and refuses to run when the list is missing, empty, or malformed; no
environment variable can replace it. The picker needs fzf 0.51 or newer.

The name index is a zstd-compressed path list in `$XDG_RUNTIME_DIR` (memory,
about 15 MB), so refreshes cause no disk writes. Its file name is keyed by the
exclusion list, so a changed list is never answered from an older index.
`file-finder-index.timer` rebuilds it every 15 minutes, and opening the finder
also starts a refresh, swapping the fresh list in about a second later.
Installing the profile deploys the script and units; enabling the timer is a
separate, explicit step:

```bash
./install.sh --profile mirrodin --apply
systemctl --user daemon-reload
systemctl --user enable --now file-finder-index.timer
```

Test the exclusion and lookup contracts with `test/file-finder-test.sh` (also
run by `scripts/check.sh`).

## Emergency recovery (Mirrodin)

Linux recovery is separate from the HOME-relative profile installer:

```bash
scripts/setup-recovery.sh          # Read-only plan; no sudo or writes
scripts/setup-recovery.sh --apply  # Explicit apply; sudo when needed
```

This manages only `kernel.sysrq=176`, sourced from
`config/hosts/mirrodin/sysctl.d/60-workbench-recovery.conf`, installed as
root:root mode 0644 at `/etc/sysctl.d/60-workbench-recovery.conf`, and activated
without reloading unrelated sysctl files. Reapplying is idempotent. Existing
target content must match exactly; symlinks and different content are refused.
There is no automatic adoption: review and back up/move conflicting content
aside yourself before applying. Other sysctl files remain untouched; review
any later `kernel.sysrq` override separately before relying on boot persistence.

Use **S/U/B**: hold Alt+SysRq (often PrintScreen), press **S** (sync), wait for
completion, then **U** (remount read-only), wait for completion, then **B**
(reboot). Mask 176 enables sync, remount, and reboot/poweroff, not full REISUB.
This is not guaranteed GPU recovery: the kernel and keyboard must still respond.
**Emergency reboot loses unsaved work and permits physical-access denial of
service, even while locked.** The installer never reboots, changes locking,
or adds a listener, watchdog, or unlock bypass.

## Unattended administration (Mirrodin)

The operator approved full passwordless sudo for `phaedrus` on Mirrodin.
This is an account-wide grant: every process under that account can obtain
root, not only agents. Agents still run as the normal user and elevate
individual commands. No SSH login rule, desktop lock rule, or polkit default
is changed.

```bash
scripts/setup-privileges.sh          # Validate source and show plan; no writes
scripts/setup-privileges.sh --apply  # Install with sudo, or run as root
```

The source is `config/hosts/mirrodin/sudoers.d/zz-workbench-phaedrus`.
The installer validates the source and existing policy, then creates
`/etc/sudoers.d/zz-workbench-phaedrus` atomically as a root:root `0440` copy.
It validates the combined policy and removes its new grant on validation
failure. Matching installs are unchanged; conflicting files, symlinks, and
incorrect metadata are refused. The grant names both `phaedrus` and `mirrodin`;
the installer also refuses another host. Normal profile installation does
not grant root.

Before the first grant, an agent without an operator-accessible terminal can
request desktop approval from this checkout:

```bash
pkexec /usr/bin/bash "$PWD/scripts/setup-privileges.sh" --apply
```

After installation, verify without using or updating cached credentials:

```bash
/usr/bin/sudo -n -k /usr/bin/id -u  # Must print 0 with no prompt
```

SSH and background jobs can then use `sudo -n` for authorized operations.
They do not need a local desktop approval. Connectivity, job survival after
disconnect, and browser/native desktop control remain separate capabilities.

To remove only this grant and validate the remaining policy from an authorized
terminal, then clear the account's cached sudo credentials:

```bash
sudo /usr/bin/bash -c 'rm -- /etc/sudoers.d/zz-workbench-phaedrus && visudo -c'
sudo -K
```

This restores the remaining host policy, including password-required general
administration and the existing narrow passwordless commands.

## Meeting transcription (Mirrodin)

Local meeting recording, transcription, and speaker diarization via `meet` (available on `PATH` via `bin/` or `~/.local/bin/meet`):

```bash
# First-time setup: installs whisper and diarization stack into ~/.local/share/meet-venv
meet setup

# Record a call, transcribe, diarize, and write note to ~/Documents/daybook/meetings/
meet session

# Transcribe and diarize an existing audio file
meet all <audio-file>

# Watch folder for incoming audio files to auto-transcribe
meet watch [inbox-directory]
```

Capture requires Linux PulseAudio/PipeWire (`pactl`) and ffmpeg. GPU acceleration uses CUDA when available.
