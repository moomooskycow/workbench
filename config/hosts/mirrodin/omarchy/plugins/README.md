# Mirrodin custom Omarchy plugins

This directory is the durable source for four copied Omarchy plugin directories:

- `phaedrus.headphone-battery`: original local headphone status widget. Its
  product names and USB vendor/product IDs identify supported hardware; no
  serial number, Bluetooth address, account, credential, or user-state value is
  stored in the source.
- `phaedrus.idle`: clone of `omarchy.idle` that starts the screensaver but does
  not automatically lock.
- `phaedrus.lock`: clone of `omarchy.lock` that keeps the display illuminated
  while the session is locked.
- `phaedrus.menu`: clone of `omarchy.menu` with a wider card/dmenu and an
  application-entry fallback for cloned-plugin loading.

The three clones are based on Omarchy `v4.0.3`, commit
`0534987009061cbe2dacdde4ad564092ab698d12`, from
<https://github.com/basecamp/omarchy>. Their unchanged and modified upstream
files remain subject to Omarchy's MIT license, preserved in
`LICENSE.omarchy`. The packaged Omarchy 4.0.3 files on Mirrodin were verified
byte-for-byte against that tag before this snapshot was recorded.

`SHA256SUMS` covers every active runtime file. The two dated `.bak` files found
beside `phaedrus.idle` were deliberately excluded: they are local backup state,
not active plugin behavior or public source.

## Restore

Preview first:

```bash
scripts/restore-omarchy-plugins.sh
```

Copy any missing snapshots as real directories (never symlinks):

```bash
scripts/restore-omarchy-plugins.sh --apply
```

A different existing directory is not overwritten. To make an explicit repair,
back up each conflicting directory under
`~/.local/state/workbench/backups/omarchy-plugins/` and replace it:

```bash
scripts/restore-omarchy-plugins.sh --apply --adopt
```

The restore command validates source and staged copies, preserves executable
modes, and compares copied trees by relative path, mode, and bytes. It does not
edit `shell.json`, enable or disable plugins, call Omarchy shell IPC, or restart
the desktop. Plugin enablement and layout therefore remain whatever the user's
shell configuration already declares.
