# User stories

## US-001 Keep host-private shortcuts out of public Workbench releases

When I install Workbench's Omarchy bindings, I want my host-only shortcuts to load after the shared bindings without publishing their commands or paths, so I can update the release without losing those local choices.

Criteria:
1. WHEN the local bindings file is absent, THE SYSTEM SHALL load the shared bindings without an error.
2. WHEN `~/.config/hypr/bindings.local.lua` contains valid overrides, THE SYSTEM SHALL apply them after shared bindings and a Workbench install SHALL leave that file untouched.
3. WHEN the local file exists but contains invalid Lua, THE SYSTEM SHALL report a config reload error instead of silently skipping the overrides.

No-gos: Do not put private shortcut values in public source. Do not add the local file to the Workbench installation manifest.

Evidence: `config/shared/hypr/bindings.lua`, `config/hosts/mirrodin/manifest.tsv`, a Hyprland reload and config-error check, and the live shortcut list.

## US-002 Find any file in my home folder from a key binding

When I press Super+Ctrl+/ on Mirrodin, I want a Spotlight-style fuzzy finder over my whole home folder, including hidden folders such as `~/.local`, so I can open, reveal, or hand off a file without remembering where it lives.

Criteria:
1. WHEN I press Super+Ctrl+/, THE SYSTEM SHALL open a floating fuzzy finder listing indexed file and folder names under my home folder, or focus the one already open.
2. WHEN a file exists in a hidden folder at the last index refresh, THE SYSTEM SHALL show it for a matching query in under one second.
3. WHEN a file was created after the last timer refresh, THE SYSTEM SHALL list it once the refresh that opening the finder starts completes.
4. WHEN I switch to text search with Ctrl+T, THE SYSTEM SHALL list matching lines from file contents under the same exclusions.
5. WHEN I press Enter, Ctrl+O, Ctrl+Y, or Ctrl+F on a result, THE SYSTEM SHALL open it with its default application, show it in the file manager, copy its absolute path, or copy it as a file (`text/uri-list`) respectively, then close the finder.
6. THE SYSTEM SHALL never index, list, preview, or search the password store, `~/.gnupg`, `~/.ssh`, keyrings, `.env` or `.dev.vars` files, or the other secret files named in the exclusion list.
7. THE SYSTEM SHALL skip version-control internals, dependency folders, caches, and package stores.
8. WHEN the exclusion list is missing, empty, or malformed, THE SYSTEM SHALL refuse to index or search.
9. WHEN a result is a symbolic link, THE SYSTEM SHALL preview only its target path, and SHALL refuse every action unless the link resolves to an allowed path inside the home folder; results under a symlinked folder SHALL be refused.

No-gos: Do not let an environment variable replace the exclusion list. Do not walk, search, or preview through symbolic links.

Evidence: `test/file-finder-test.sh`, the installed `file-finder-index.timer`, a timed query for a probe file in a hidden folder, and the live shortcut list.

## US-003 Type Dvorak in every application

When I type on Mirrodin, I want Dvorak in every window, including Chromium and other clients that take keys through fcitx5, so the layout does not change with the application I am in.

Criteria:
1. WHEN the Workbench fcitx5 profile is installed and fcitx5 reloads, THE SYSTEM SHALL report `keyboard-us-dvorak` as fcitx5's current input method.
2. WHEN Hyprland is on layout 0, THE SYSTEM SHALL produce Dvorak characters in Chromium text fields and in applications that bypass fcitx5.
3. WHEN I switch Hyprland to layout 1, THE SYSTEM SHALL keep US QWERTY available for applications that read keys directly from Hyprland, such as games.

No-gos: Do not remove Hyprland's QWERTY layout 1. Do not change Chromium flags to bypass the input method.

Evidence: `config/shared/fcitx5/profile`, `config/shared/hypr/input.lua`, `fcitx5-remote -n` after reload, and typing in Chromium.
