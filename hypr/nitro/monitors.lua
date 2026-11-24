-- ▗▖  ▗▖▗▄▄▄▖▗▄▄▄▖▗▄▄▖  ▗▄▖      ▗▄▖  ▗▄▄▖
-- ▐▛▚▖▐▌  █    █  ▐▌ ▐▌▐▌ ▐▌    ▐▌ ▐▌▐▌
-- ▐▌ ▝▜▌  █    █  ▐▛▀▚▖▐▌ ▐▌    ▐▌ ▐▌ ▝▀▚▖
-- ▐▌  ▐▌▗▄█▄▖  █  ▐▌ ▐▌▝▚▄▞▘    ▝▚▄▞▘▗▄▄▞▘
-- Github : @Nitro-OS

-- ============================================
-- MONITOR CONFIGURATION
-- ============================================
-- Customize monitor settings to match your setup.
-- Run `hyprctl monitors all` to see available monitors.
--
-- output   : Monitor name (e.g. HDMI-A-1, eDP-1)
-- mode     : Resolution and refresh rate (e.g. 1920x1080@60)
-- position : Monitor position (e.g. 0x0, 1920x0)
-- scale    : Display scaling (e.g. 1, 1.25, 1.5)
--
-- Adjust or remove monitors you don't use.
-- ============================================

hl.monitor({
  output = "HDMI-A-1",
  mode = "1920x1080@60",
  position = "0x0",
  scale = 1,
})

hl.monitor({
  output = "eDP-1",
  mode = "preferred",
  position = "1920x0",
  scale = 1,
})
