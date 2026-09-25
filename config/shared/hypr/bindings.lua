-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")
-- Voice dictation (Super + R for raw, Super + Shift + R for clean - drops Alt, frees D for left)
hl.unbind("SUPER + grave")
o.bind("SUPER + R", "Toggle raw dictation", "cantrip toggle --postproc raw")
o.bind("SUPER + SHIFT + R", "Toggle clean dictation", "cantrip toggle --postproc clean")

-- Unbind defaults that conflict with Dvorak DHTN (physical HJKL) navigation
hl.unbind("SUPER + T")         -- Default float toggle -> moved to Super + Y
hl.unbind("SUPER + J")         -- Default split toggle -> moved to Super + \
hl.unbind("SUPER + SHIFT + D") -- Default Docker TUI -> freed for swap left
hl.unbind("SUPER + SHIFT + N") -- Default Editor -> moved to Super + E

-- Replaced functions
o.bind("SUPER + Y", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + backslash", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + E", "Editor", { omarchy = "editor" })

-- Dvorak DHTN window navigation (physical HJKL: D=left, H=down, T=up, N=right)
o.bind("SUPER + D", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + H", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + T", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + N", "Focus on right window", hl.dsp.focus({ direction = "r" }))

-- Dvorak DHTN window swap (Super + Shift + DHTN)
o.bind("SUPER + SHIFT + D", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + H", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + T", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + N", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
-- Omarchy workspace cycling on Dvorak home row (Super + Ctrl + DHTN)
hl.unbind("SUPER + CTRL + D") -- displaced Display widget
hl.unbind("SUPER + CTRL + N") -- displaced Nightlight toggle
hl.unbind("SUPER + CTRL + H") -- displaced Hardware menu
hl.unbind("SUPER + CTRL + T") -- displaced Activity (btop)

-- Rebound displaced utilities
o.bind("SUPER + B", "Activity (btop)", { tui = "btop" })
o.bind("SUPER + CTRL + SHIFT + D", "Display settings", "omarchy-shell shell toggle omarchy.monitor")
o.bind_toggle("SUPER + CTRL + SHIFT + N", "Toggle nightlight", "nightlight")
o.bind("SUPER + CTRL + SHIFT + H", "Hardware menu", "omarchy-menu toggle hardware")

-- Workspace navigation
o.bind("SUPER + CTRL + N", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + CTRL + D", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + H", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + CTRL + T", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))

-- Unbind obsolete Tmux bindings
hl.unbind("SUPER + ALT + RETURN")
hl.unbind("SUPER + ALT + K")

-- QWERTY for games (StarCraft auto-switches; this covers anything else)
o.bind("SUPER + ALT + Q", "Toggle QWERTY for games", os.getenv("HOME") .. "/.config/hypr/switch-xkblayout.sh next")

-- US-002: fuzzy file finder across the home folder ("/" = search; off the Dvorak home row)
o.bind("SUPER + CTRL + SLASH", "Find files", os.getenv("HOME") .. "/.local/bin/file-finder launch")


-- Workspace navigation & window movement (keys 1-9, 0)
local shift_symbols = {
  [1] = "exclam",
  [2] = "at",
  [3] = "numbersign",
  [4] = "dollar",
  [5] = "percent",
  [6] = "asciicircum",
  [7] = "ampersand",
  [8] = "asterisk",
  [9] = "parenleft",
  [10] = "parenright",
}

for workspace = 1, 10 do
  local key = tostring(workspace % 10)
  local sym = shift_symbols[workspace]

  -- Switch workspace: Super + <num>
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))

  -- Move window to workspace: Super + Shift + <num> (covers both raw number + shift and shifted symbol)
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = true }))
  o.bind("SUPER + " .. sym, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = true }))
  o.bind("SUPER + SHIFT + " .. sym, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = true }))

  -- Move window silently to workspace (Super + Ctrl + Shift instead of awkward Alt)
  o.bind("SUPER + CTRL + SHIFT + " .. key, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
  o.bind("SUPER + CTRL + " .. sym, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
  o.bind("SUPER + CTRL + SHIFT + " .. sym, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

-- US-001: host-only shortcuts live outside the public Workbench release.
local private_bindings = os.getenv("HOME") .. "/.config/hypr/bindings.local.lua"
local private_file = io.open(private_bindings, "r")
if private_file then
  private_file:close()
  dofile(private_bindings)
end
