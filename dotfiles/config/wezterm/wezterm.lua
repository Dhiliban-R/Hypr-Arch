local wezterm = require 'wezterm'
local config = {}

-- Enable Wayland (keeping your original setting, but placing it within the config table)
config.enable_wayland = false

-- Font settings from Kitty
config.font_size = 11
config.font = wezterm.font("DejaVu Sans Mono")

-- Background opacity from Kitty (WezTerm's is inverse: 0.1 in Kitty means 0.9 transparent in WezTerm)
config.window_background_opacity = 0.0

-- Move tab bar to bottom
config.tab_bar_at_bottom = true


-- Catppuccin-Mocha color scheme from Kitty
config.colors = {
    foreground = "#CDD6F4",
    background = "#000000",
    cursor_bg = "#F5E0DC",
    cursor_fg = "#1E1E2E",
    selection_bg = "#F5E0DC",
    selection_fg = "#1E1E2E",

    -- Ansi colors
    ansi = {
        "#45475A", -- black
        "#F38BA8", -- red
        "#A6E3A1", -- green
        "#F9E2AF", -- yellow
        "#89B4FA", -- blue
        "#F5C2E7", -- magenta
        "#94E2D5", -- cyan
        "#BAC2DE", -- white
    },

    -- Bright ansi colors
    brights = {
        "#585B70", -- bright black
        "#F38BA8", -- bright red
        "#A6E3A1", -- bright green
        "#F9E2AF", -- bright yellow
        "#89B4FA", -- bright blue
        "#F5C2E7", -- bright magenta
        "#94E2D5", -- bright cyan
        "#A6ADC8", -- bright white
    },

    -- URL underline color
    -- Tab bar colors
    tab_bar = {
        active_tab = {
            bg_color = "rgba(0, 0, 0, 0.05)",
            fg_color = "#CDD6F4",
        },
        inactive_tab = {
            bg_color = "rgba(0, 0, 0, 0.05)",
            fg_color = "#CDD6F4",
        },
        background = "rgba(0, 0, 0, 0.05)",
    },
}

config.keys = {
  -- New tab
  { key = "t", mods = "CTRL", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  -- Close tab
  { key = "w", mods = "CTRL", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
  -- Close pane
  { key = "x", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
  -- Next tab
  { key = "RightArrow", mods = "CTRL", action = wezterm.action.ActivateTabRelative(1) },
  -- Previous tab
  { key = "LeftArrow", mods = "CTRL", action = wezterm.action.ActivateTabRelative(-1) },

  -- Split pane horizontally
  { key = "\", mods = "CTRL", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  -- Split pane vertically
  { key = "|", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  -- Close pane


  -- Activate pane in direction
  { key = "j", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "l", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "i", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "k", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },

  -- Move cursor between words
  { key = "LeftArrow", mods = "ALT", action = wezterm.action.SendString("\x1bb") },
  { key = "RightArrow", mods = "ALT", action = wezterm.action.SendString("\x1bf") },

  -- Copy to clipboard
  { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("ClipboardAndPrimarySelection") },
  -- Paste from clipboard
  { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },

  -- Increase font size
  { key = "=", mods = "CTRL", action = wezterm.action.IncreaseFontSize },
  -- Decrease font size
  { key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
  -- Reset font size
  { key = "0", mods = "CTRL", action = wezterm.action.ResetFontSize },
  -- Shift+Enter to move to next line (insert newline)
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },
}

return config
