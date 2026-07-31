-- Beautiful WezTerm Configuration
-- Optimized for macOS stability and aesthetics

local wezterm = require('wezterm')
local config = wezterm.config_builder()
local act = wezterm.action

-- ====================
-- APPEARANCE
-- ====================

-- Ember — warm charcoal + copper (matches Ghostty Ember)
config.color_schemes = config.color_schemes or {}
config.color_schemes['Ember'] = {
  foreground = '#d5cec4',
  background = '#131119',
  cursor_bg = '#e8a849',
  cursor_fg = '#131119',
  cursor_border = '#e8a849',
  selection_fg = '#f0e4d4',
  selection_bg = '#3d2e1f',
  ansi = {
    '#1c1820', '#d46a6a', '#8aab7c', '#d4a54c',
    '#7a9ec2', '#b08cb8', '#7aab9c', '#c8c0b4',
  },
  brights = {
    '#4a4458', '#e88888', '#a5c896', '#e8c36e',
    '#94b8d8', '#c8a8d0', '#96c8b8', '#e8e0d4',
  },
}
config.color_schemes['Ember Dawn'] = {
  foreground = '#2c2622',
  background = '#f4efe8',
  cursor_bg = '#c47a2a',
  cursor_fg = '#f4efe8',
  cursor_border = '#c47a2a',
  selection_fg = '#2c2622',
  selection_bg = '#e4d4be',
  ansi = {
    '#2c2622', '#b04040', '#5a7a4c', '#8a5a00',
    '#4a6a8a', '#7a5a82', '#4a7a6a', '#d5cec4',
  },
  brights = {
    '#5a5248', '#c25050', '#6a8a5c', '#8f5f00',
    '#5a7ea0', '#8a6a92', '#5a8a7a', '#f4efe8',
  },
}
config.color_scheme = 'Ember'

-- Typography with better spacing and fallbacks
config.font = wezterm.font_with_fallback({
  { family = 'JetBrains Mono', weight = 'Medium' },
  'Symbols Nerd Font Mono',
  'Apple Color Emoji',
})
config.font_size = 14.0
config.line_height = 1.3
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }

-- Soft warm lift — no purple gradient
config.window_background_gradient = {
  colors = { '#131119', '#1c1820' },
  orientation = { Linear = { angle = -45.0 } },
}
config.macos_window_background_blur = 20

-- Dim inactive panes for visual depth
config.inactive_pane_hsb = {
  saturation = 0.24,
  brightness = 0.5,
}

-- ====================
-- PERFORMANCE
-- ====================

-- Conservative settings to avoid input lag
config.front_end = 'WebGpu'
config.max_fps = 30
config.animation_fps = 30
config.scrollback_lines = 10000

-- Smooth cursor
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 800
config.cursor_blink_ease_in = 'EaseIn'
config.cursor_blink_ease_out = 'EaseOut'

-- ====================
-- BEHAVIOR
-- ====================

config.default_prog = { '/bin/zsh', '-l' }
config.audible_bell = 'Disabled'
config.window_close_confirmation = 'AlwaysPrompt'

-- ====================
-- UNIX DOMAINS (tmux-like persistence)
-- ====================
-- Separates GUI from server. Cmd+Q only kills GUI; server persists.
-- Reopen WezTerm = instant reconnect to existing tabs.
config.unix_domains = {
  { name = 'unix' },
}
config.default_gui_startup_args = { 'connect', 'unix' }
config.automatically_reload_config = true

-- CRITICAL: Disable kitty keyboard protocol (causes input doubling on macOS)
config.enable_kitty_keyboard = false

-- ====================
-- QUICK SELECT PATTERNS
-- ====================
config.quick_select_patterns = {
  -- Git short hashes (7-40 hex chars)
  '[0-9a-f]{7,40}',
  -- File paths
  '[.\\w/~-]+/[.\\w/-]+',
}

-- ====================
-- HYPERLINK RULES
-- ====================
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- GitHub user/repo → clickable link
table.insert(config.hyperlink_rules, {
  regex = [[["]?([\w\d]{1}[-\w\d]+)/([-\w\d\.]+)["]?]],
  format = 'https://github.com/$1/$2',
})

-- ====================
-- TAB BAR & WINDOW
-- ====================

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.tab_max_width = 32
config.window_decorations = 'RESIZE'
config.window_padding = { left = 12, right = 12, top = 12, bottom = 12 }

-- Ember colors for tab bar
local ember = {
  bg = '#131119',
  fg = '#d5cec4',
  subtle = '#6f6878',
  muted = '#9a9288',
  love = '#d46a6a',
  gold = '#d4a54c',
  foam = '#7aab9c',
  iris = '#e8a849', -- copper accent (kept key name for call sites)
}

-- Powerline separators (nerd fonts)
local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

-- Process icons
local process_icons = {
  ['bash'] = wezterm.nerdfonts.cod_terminal_bash,
  ['zsh'] = wezterm.nerdfonts.dev_terminal,
  ['nvim'] = wezterm.nerdfonts.custom_vim,
  ['vim'] = wezterm.nerdfonts.dev_vim,
  ['node'] = wezterm.nerdfonts.mdi_hexagon,
  ['git'] = wezterm.nerdfonts.fa_git,
  ['cargo'] = wezterm.nerdfonts.dev_rust,
  ['go'] = wezterm.nerdfonts.seti_go,
  ['python'] = wezterm.nerdfonts.dev_python,
  ['ruby'] = wezterm.nerdfonts.cod_ruby,
  ['docker'] = wezterm.nerdfonts.linux_docker,
}

-- Format tab title with icon and directory
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local title = tab.tab_title

  -- Get process name
  local process = pane.foreground_process_name
  local process_name = process and process:match('([^/]+)$') or 'zsh'
  local icon = process_icons[process_name] or wezterm.nerdfonts.cod_terminal

  -- Get directory name
  local cwd = pane.current_working_dir
  local dir = 'home'
  if cwd then
    local cwd_uri = type(cwd) == 'userdata' and cwd.file_path or cwd
    dir = cwd_uri:match('([^/]+)/?$') or 'home'
  end

  -- Use custom title if set, otherwise format as "icon dir/"
  if not title or #title == 0 then
    title = string.format(' %s %s/ ', icon, dir)
  end

  -- Colors
  local bg = ember.bg
  local fg = ember.subtle

  if tab.is_active then
    bg = ember.muted
    fg = ember.bg
  elseif hover then
    bg = '#2a273f'
    fg = ember.fg
  end

  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = title },
  }
end)

-- Powerline status bar with git branch and battery
wezterm.on('update-right-status', function(window, pane)
  local workspace = window:active_workspace()
  local time = wezterm.strftime('%H:%M')
  local hostname = wezterm.hostname():match('([^.]+)')

  -- Build segments
  local segments = {}

  -- Git branch (if in repo)
  local success, stdout = wezterm.run_child_process({ 'git', 'branch', '--show-current' })
  if success then
    local branch = stdout:gsub('%s+', '')
    if #branch > 0 then
      table.insert(segments, {
        text = ' ' .. wezterm.nerdfonts.dev_git_branch .. ' ' .. branch,
        color = ember.love
      })
    end
  end

  -- Workspace (if not default)
  if workspace ~= 'default' then
    table.insert(segments, { text = ' ' .. workspace, color = ember.iris })
  end

  -- Battery
  for _, b in ipairs(wezterm.battery_info()) do
    local charge = b.state_of_charge * 100
    local icon = charge > 50 and wezterm.nerdfonts.md_battery or wezterm.nerdfonts.md_battery_low
    table.insert(segments, {
      text = ' ' .. icon .. ' ' .. string.format('%.0f%%', charge),
      color = ember.iris
    })
  end

  -- Time and hostname
  table.insert(segments, { text = ' ' .. wezterm.nerdfonts.md_clock .. ' ' .. time, color = ember.foam })
  table.insert(segments, { text = ' ' .. wezterm.nerdfonts.md_laptop .. ' ' .. hostname, color = ember.gold })

  -- Format with powerline arrows
  local elements = {}
  for i, seg in ipairs(segments) do
    table.insert(elements, { Foreground = { Color = seg.color } })
    table.insert(elements, { Text = SOLID_LEFT_ARROW })
    table.insert(elements, { Background = { Color = seg.color } })
    table.insert(elements, { Foreground = { Color = ember.bg } })
    table.insert(elements, { Text = seg.text .. ' ' })
  end

  window:set_right_status(wezterm.format(elements))
end)

-- Window title with zoom indicator and tab count
wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
  local zoomed = tab.active_pane.is_zoomed and '[Z] ' or ''
  local index = #tabs > 1 and string.format('[%d/%d] ', tab.tab_index + 1, #tabs) or ''
  return zoomed .. index .. tab.active_pane.title
end)

-- Mode indicator in left status (shows RESIZE, COPY, etc.)
wezterm.on('update-status', function(window, pane)
  local name = window:active_key_table()
  if name then
    window:set_left_status(wezterm.format({
      { Foreground = { Color = ember.love } },
      { Background = { Color = ember.bg } },
      { Text = ' [' .. name:upper() .. '] ' },
    }))
  else
    window:set_left_status('')
  end
end)

-- ====================
-- TMUX-STYLE KEYBINDINGS
-- ====================

config.leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 1000 }

config.keys = {
  -- Tab management
  { key = 'c', mods = 'LEADER', action = act.SpawnTab('CurrentPaneDomain') },
  { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane({ confirm = true }) },
  { key = 'w', mods = 'LEADER', action = act.ShowTabNavigator },

  -- Pane splits (visual mnemonics: | = vertical divider, - = horizontal divider)
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = '-', mods = 'LEADER', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },

  -- Pane navigation
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection('Left') },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection('Down') },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection('Up') },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection('Right') },

  -- Pane zoom
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },

  -- Fullscreen
  { key = 'Enter', mods = 'LEADER', action = act.ToggleFullScreen },

  -- Copy mode
  { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },

  -- Quick Select (fuzzy capture URLs, paths, hashes)
  { key = 'u', mods = 'LEADER', action = act.QuickSelect },

  -- Workspace fuzzy switcher
  { key = 's', mods = 'LEADER', action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }) },

  -- Pane resize mode (h/j/k/l to resize, Escape to exit)
  { key = 'r', mods = 'LEADER', action = act.ActivateKeyTable({ name = 'resize_pane', one_shot = false }) },

  -- Quit protection (Dvorak: Q adjacent to X)
  { key = 'q', mods = 'CMD', action = act.Nop },
  { key = 'q', mods = 'CMD|SHIFT', action = act.QuitApplication },

  -- macOS standard bindings
  { key = '=', mods = 'CMD', action = act.IncreaseFontSize },
  { key = '-', mods = 'CMD', action = act.DecreaseFontSize },
  { key = '0', mods = 'CMD', action = act.ResetFontSize },
  { key = 'K', mods = 'CMD', action = act.ClearScrollback('ScrollbackAndViewport') },

  -- Smart Cmd+C: copy if selection, else send Ctrl+C
  { key = 'c', mods = 'CMD', action = wezterm.action_callback(function(window, pane)
    local has_selection = window:get_selection_text_for_pane(pane) ~= ''
    if has_selection then
      window:perform_action(act.CopyTo('Clipboard'), pane)
    else
      window:perform_action(act.SendKey({ key = 'c', mods = 'CTRL' }), pane)
    end
  end) },

  { key = 'v', mods = 'CMD', action = act.PasteFrom('Clipboard') },
  { key = 'n', mods = 'CMD', action = act.SpawnWindow },
  { key = 'w', mods = 'CMD', action = act.CloseCurrentPane({ confirm = true }) },
  { key = 'r', mods = 'CMD|SHIFT', action = act.ReloadConfiguration },
}

-- Key table for pane resizing
config.key_tables = {
  resize_pane = {
    { key = 'h', action = act.AdjustPaneSize({ 'Left', 5 }) },
    { key = 'j', action = act.AdjustPaneSize({ 'Down', 5 }) },
    { key = 'k', action = act.AdjustPaneSize({ 'Up', 5 }) },
    { key = 'l', action = act.AdjustPaneSize({ 'Right', 5 }) },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'Enter', action = 'PopKeyTable' },
  },
}

-- Tab switching with leader + number
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'LEADER',
    action = act.ActivateTab(i - 1),
  })
end

return config
