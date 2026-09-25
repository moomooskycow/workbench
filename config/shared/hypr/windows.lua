-- Personal window rules

-- Cursor-hijack mitigation: keep mouse-follow from yanking focus into/out of
-- Proton games mid-pointer-grab. steam_app_* = all Proton apps; "Minecraft
-- Launcher" is its Hyprland class. Clicks still focus; only unfocus-on-hover.
o.window("^(steam_app_.*|Minecraft Launcher)$", { no_follow_mouse = true })

-- Microsoft Outlook webapp
o.window("(^chrome-outlook\\.office\\.com.*$|^outlook-account.*$)", {
  tag = "-default-opacity",
  opacity = "1.0 0.985",
})

-- Microsoft Teams webapp
o.window("(^chrome-teams\\.microsoft\\.com.*$|^teams-account.*$)", {
  tag = "-default-opacity",
  opacity = "1.0 0.985",
})

-- Time Tracker QA smoke test windows: isolate to silent workspace without stealing focus
o.window({ title = ".*Smoke Test.*" }, {
  float = true,
  no_initial_focus = true,
  workspace = "special silent",
})
o.window({ initial_title = ".*Smoke Test.*" }, {
  float = true,
  no_initial_focus = true,
  workspace = "special silent",
})

-- StarCraft II (Battle.net/Proton) binds hotkeys to QWERTY keysyms. Keep the
-- launcher on Dvorak; only windows titled StarCraft get layout 1.
local layout_script = (os.getenv("HOME") or "") .. "/.config/hypr/switch-xkblayout.sh"
local layout_wanted

local function wants_qwerty(win)
  if not win then
    return false
  end
  local title = string.lower(tostring(win.title or "") .. " " .. tostring(win.initial_title or ""))
  return title:find("starcraft", 1, true) ~= nil
end

local function apply_game_layout(win)
  local idx = wants_qwerty(win) and 1 or 0
  if idx == layout_wanted then
    return
  end
  layout_wanted = idx
  hl.exec_cmd(layout_script .. " " .. tostring(idx))
end

local function restore_unless_starcraft_focused()
  apply_game_layout(hl.get_active_window())
end


hl.on("window.active", apply_game_layout)
hl.on("window.open", function(win)
  if win and win.active then
    apply_game_layout(win)
  end
end)
hl.on("window.title", function(win)
  if win and win.active then
    apply_game_layout(win)
  end
end)
hl.on("window.close", function(win)
  if wants_qwerty(win) then
    layout_wanted = nil
    restore_unless_starcraft_focused()
  end
end)
hl.on("window.destroy", function(win)
  if wants_qwerty(win) then
    layout_wanted = nil
    restore_unless_starcraft_focused()
  end
end)

-- Compositor restart / hot-reload resets the keyboard group state to 0.
-- If SC2 was focused at that moment (crash mid-game, reload while
-- playing) no window event fires, so re-apply the layout for the
-- currently focused window two seconds after the compositor is up.
local function recover_layout_after_start()
  hl.exec_cmd(
    "sleep 2; hyprctl activewindow 2>/dev/null | grep -qi starcraft"
      .. " && ~/.config/hypr/switch-xkblayout.sh 1 || true"
  )
end
hl.on("hyprland.start", recover_layout_after_start)

-- US-002: the file finder opens as a centered floating panel.
o.window("^workbench\\.file-finder$", { float = true, center = true, size = { 1400, 800 } })
