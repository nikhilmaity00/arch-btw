-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
-- require("default.hypr.omarchy")
local guide_root = (os.getenv("HOME") or "") .. "/.config/omarchy/plugins/io.github.ctl0v0.keybinding-guide/hypr"
local function load_guide_file(name)
  local path = guide_root .. "/" .. name
  local file = io.open(path, "r")
  if file then
    file:close()
    dofile(path)
  end
end

load_guide_file("keybinding-guide-preload.lua")
require("default.hypr.omarchy")
load_guide_file("keybinding-guide.lua")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })


-- Load settings written by OmaSettings (omasettings:managed).
require("hypr.omasettings")
