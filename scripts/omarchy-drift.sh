#!/usr/bin/env bash
# Managed-config drift guard for the workbench manifest.
#
# The manifest symlinks release files into $HOME (see install.sh). Two failure
# modes desync the repo from the live config; this guard catches both and is
# wired into scripts/check.sh so a commit can't ride on top of the drift:
#
#   1. A tool (omarchy update, an agent, a hand edit) replaces a symlink with
#      a plain file, or mutates a release file through the link.
#   2. Someone edits the live file and the change never reaches the repo.
#
# Semantics per manifest target (profile = $1 or hostname; serenity|mirrodin):
#   symlink -> workbench release : content must match that release's copy of
#                                  the source (write-through corruption), or we
#                                  fail.
#   plain file                   : content must match the repo working tree,
#                                  or we fail (live edit lost to version
#                                  control). A match is "pending apply" — the
#                                  normal pre-`./install.sh --apply` state.
#   missing                      : fail (a hyprland config file that vanished
#                                  is a silent breakage), unless the current
#                                  release predates the entry: that is a new
#                                  managed file awaiting its first apply.
#   target outside this host's install scope, or no install on this machine   :
#                                  skip cleanly, so CI and other hosts pass.
#
# exit 0 = clean or skipped, 1 = drift detected.

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

profile="${1:-$(hostname -s)}"
case "$profile" in serenity|mirrodin) ;; *) profile="$(hostname -s)" ;; esac

manifest="$ROOT_DIR/config/hosts/$profile/manifest.tsv"
current_file="$HOME/.local/state/workbench/current-$profile"

if [ ! -f "$manifest" ]; then
  echo "omarchy-drift: no manifest for profile '$profile'; skipping."
  exit 0
fi
if [ ! -f "$current_file" ]; then
  echo "omarchy-drift: no workbench install for profile '$profile' on this host; skipping."
  exit 0
fi
current_release="$(cat "$current_file")"
if [ ! -d "$current_release" ]; then
  echo "omarchy-drift: current release missing: $current_release" >&2
  exit 1
fi

fail=0
while IFS='|' read -r item source target; do
  [[ "$item" == \#* ]] && continue
  [ -n "$source" ] || continue
  target_path="$HOME/$target"
  repo_source="$ROOT_DIR/$source"

  if [ ! -e "$target_path" ] && [ ! -L "$target_path" ]; then
    if [ ! -e "$current_release/$source" ]; then
      echo "pending    [$item] $target (new managed file; run ./install.sh --apply to install)"
      continue
    fi
    echo "MISSING    [$item] $target (managed file is absent)"
    fail=1
    continue
  fi

  if [ -L "$target_path" ]; then
    link_target="$(readlink "$target_path")"
    case "$link_target" in
      "$HOME/.local/share/workbench/releases/"*)
        # link_target looks like <release>/config/<...>; the release root is
        # the first path element after releases/.
        rel="${link_target#"$HOME/.local/share/workbench/releases/"}"
        release_root="$HOME/.local/share/workbench/releases/${rel%%/*}"
        linked_release_source="$release_root/$source"
        if [ ! -e "$linked_release_source" ]; then
          echo "DRIFT      [$item] $target -> $link_target (release has no $source)"
          fail=1
        elif ! cmp -s "$linked_release_source" "$target_path"; then
          echo "DRIFT      [$item] $target (symlinked content differs from its release copy of $source)"
          fail=1
        elif [ "$release_root" != "$current_release" ]; then
          echo "ok-stale   [$item] $target (symlinked into $release_root, current install is $current_release)"
        else
          echo "ok         [$item] $target"
        fi
        ;;
      *)
        echo "UNMANAGED  [$item] $target -> $link_target (not a workbench release link)"
        fail=1
        ;;
    esac
    continue
  fi

  # Plain file where a release symlink belongs.
  if [ ! -e "$repo_source" ]; then
    echo "untracked  [$item] $target (no $source in repo working tree; repo stopped managing it?)"
    continue
  fi
  if cmp -s "$repo_source" "$target_path"; then
    echo "pending    [$item] $target (plain file matching repo; run ./install.sh --apply to link)"
  else
    echo "LIVE-EDIT  [$item] $target (live file differs from $source in the repo — uncommitted live change)"
    fail=1
  fi
done < "$manifest"

if [ "$fail" -ne 0 ]; then
  echo "omarchy-drift: drift detected for profile '$profile' (release $current_release)." >&2
  exit 1
fi
echo "omarchy-drift: clean for profile '$profile' (release $current_release)."
exit 0