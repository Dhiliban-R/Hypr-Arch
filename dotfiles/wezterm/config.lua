local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.default_cursor_style = "SteadyBar"
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false
config.window_decorations = "RESIZE"
config.check_for_updates = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.font_size = 10
config.window_background_opacity = 0.0
config.text_background_opacity = 0.0
config.font = wezterm.font("JetBrains Mono", { weight = "Bold" })
config.enable_tab_bar = false
config.enable_wayland = false

config.window_padding = {
	left = 7,
	right = 5,
	top = 2,
	bottom = 0,
}

config.keys = {
  -- New tab
  { key = "t", mods = "CTRL", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  -- Close tab
  { key = "w", mods = "CTRL", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
  -- Close pane
  { key = "x", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
  -- Split pane horizontally
  { key = "\\", mods = "CTRL", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  -- Split pane vertically
  { key = "|", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Activate pane in direction (Vim-style)
  { key = "j", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "l", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "i", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "k", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },

  -- Navigation & Selection
  { key = "Backspace", mods = "CTRL", action = wezterm.action.SendString("\x17") },
  { key = "Delete", mods = "CTRL", action = wezterm.action.SendString("\x1bd") },

  { key = "LeftArrow", mods = "CTRL", action = wezterm.action.SendString("\x1b[1;5D") },
  { key = "RightArrow", mods = "CTRL", action = wezterm.action.SendString("\x1b[1;5C") },

  { key = "LeftArrow", mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x1b[1;6D") },
  { key = "RightArrow", mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x1b[1;6C") },
  { key = "UpArrow", mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x1b[1;6A") },
  { key = "DownArrow", mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x1b[1;6B") },

  { key = "LeftArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Down") },

  { key = "LeftArrow", mods = "CTRL|ALT", action = wezterm.action.ActivateTabRelative(-1) },
  { key = "RightArrow", mods = "CTRL|ALT", action = wezterm.action.ActivateTabRelative(1) },

  -- Copy to clipboard
  { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("ClipboardAndPrimarySelection") },
  -- Paste from clipboard
  { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },

  -- Select All (Copy all text in the buffer)
  {
    key = "a",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
      local dims = pane:get_dimensions()
      local text = pane:get_text_from_region(0, 0, dims.scrollback_rows + dims.viewport_rows, dims.cols)
      window:copy_to_clipboard(text)
    end),
  },

  -- Enter = proceed
  { key = "Enter", action = wezterm.action.SendString("\r") },
  -- Shift+Enter = Move Next line
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\x1b\r") },

  -- Open fresh editor
  { key = "f", mods = "SHIFT|SUPER", action = wezterm.action.SpawnCommandInNewWindow { args = { "fresh" } } },
}

config.hyperlink_rules = {
	{
		regex = "\\((\\w+://\\S+)\\)",
		format = "$1",
		highlight = 1,
	},
	{
		regex = "\\[(\\w+://\\S+)\\]",
		format = "$1",
		highlight = 1,
	},
	{
		regex = "\\{(\\w+://\\S+)\\}",
		format = "$1",
		highlight = 1,
	},
	{
		regex = "<(\\w+://\\S+)>",
		format = "$1",
		highlight = 1,
	},
}
return config
