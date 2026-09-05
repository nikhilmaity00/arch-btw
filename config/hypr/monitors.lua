-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Managed by im0001gt.screens (Screens bar panel).

local omarchy_gdk_scale = 1
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- BEGIN im0001gt.screens
hl.monitor({ output = "desc:LG Electronics LG FULL HD 0x01010101", mode = "1920x1080@74.97", position = "0x0", scale = 1.0, vrr = 0 })
hl.monitor({ output = "eDP-1", mode = "1920x1080@60.01", position = "0x1080", scale = 1.0, vrr = 0 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.config({ misc = { vrr = 0 }, render = { cm_auto_hdr = 0 } })
-- END im0001gt.screens
