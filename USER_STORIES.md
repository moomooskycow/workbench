# User stories

## US-001 Keep host-private shortcuts out of public Workbench releases

When I install Workbench's Omarchy bindings, I want my host-only shortcuts to load after the shared bindings without publishing their commands or paths, so I can update the release without losing those local choices.

Criteria:
1. WHEN the local bindings file is absent, THE SYSTEM SHALL load the shared bindings without an error.
2. WHEN `~/.config/hypr/bindings.local.lua` contains valid overrides, THE SYSTEM SHALL apply them after shared bindings and a Workbench install SHALL leave that file untouched.
3. WHEN the local file exists but contains invalid Lua, THE SYSTEM SHALL report a config reload error instead of silently skipping the overrides.

No-gos: Do not put private shortcut values in public source. Do not add the local file to the Workbench installation manifest.

Evidence: `config/shared/hypr/bindings.lua`, `config/hosts/mirrodin/manifest.tsv`, a Hyprland reload and config-error check, and the live shortcut list.
