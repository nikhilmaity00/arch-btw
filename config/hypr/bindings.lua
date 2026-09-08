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
o.bind(
  "ALT + TAB",
  "Workspace overview",
  "omarchy-shell shell toggle mirador '{}'"
)
-- Omarchy Find file search overlay
o.bind("ALT + SPACE", "Find files & folders", "omarchy-shell shell toggle jesseburlamaque.omarchy-find")

-- BEGIN im0001gt.screens
hl.unbind("SUPER + SLASH")
hl.unbind("SUPER + ALT + SLASH")
o.bind("SUPER + SLASH", "Monitor scaling up", "/home/nikhil/.config/omarchy/plugins/im0001gt.screens/scripts/display-ctl scale up")
o.bind("SUPER + ALT + SLASH", "Monitor scaling down", "/home/nikhil/.config/omarchy/plugins/im0001gt.screens/scripts/display-ctl scale down")
-- END im0001gt.screens

-- Media playback controls
o.bind("ALT + x", "Toggle play/pause", "playerctl play-pause")
o.bind("ALT + c", "Next media track", "playerctl next")
o.bind("ALT + z", "Previous media track", "playerctl previous")
-- o.bind("SUPER + ALT + DOWN", "Stop playback", "playerctl stop")
