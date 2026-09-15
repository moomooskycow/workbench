-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

hl.config({
  input = {
    -- Reverse mouse and touchpad scroll behavior
    natural_scroll = true,

    -- Dvorak first: Hyprland resolves Super-binds against layout 0, so the
    -- desktop keeps working. Layout 1 is US QWERTY for StarCraft hotkeys.
    kb_layout = "us,us",
    kb_variant = "dvorak,",

    -- Remap CapsLock to Escape
    kb_options = "caps:escape",

    touchpad = {
      natural_scroll = true,
    },
  },
})
