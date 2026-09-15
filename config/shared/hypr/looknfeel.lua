-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- Applications may request attention, but only the operator may change focus.
hl.config({
  misc = {
    focus_on_activate = false,
  },
})

-- Ultrawide layout settings: centered half-width single window
hl.config({
  layout = {
    -- Avoid overly wide single-window layouts on wide screens (4:3 gives ~1850px on 3440x1440)
    single_window_aspect_ratio = { 4, 3 },
  },
  scrolling = {
    -- See half-width columns and keep single column half-width rather than expanding
    column_width = 0.5,
    fullscreen_on_one_column = false,
  },
})
