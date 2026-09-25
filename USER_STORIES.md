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
8. WHEN the exclusion list is missing or empty, THE SYSTEM SHALL refuse to index or search.

No-gos: Do not let an environment variable replace the exclusion list. Do not follow symbolic links into content.

Evidence: `test/file-finder-test.sh`, the installed `file-finder-index.timer`, a timed query for a probe file in a hidden folder, and the live shortcut list.
