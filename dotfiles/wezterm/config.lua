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
  -- Existing Navigation & Management
  { key = "t", mods = "CTRL", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "CTRL", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
  { key = "x", mods = "ALT", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
  { key = "\\", mods = "CTRL", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "|", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Activate pane in direction (Vim-style)
  { key = "j", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "l", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "i", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "k", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },

  -- Standard Navigation (Ctrl+Arrow = Move Word)
  { key = "LeftArrow", mods = "CTRL", action = wezterm.action.SendString("\x1b[1;5D") },
  { key = "RightArrow", mods = "CTRL", action = wezterm.action.SendString("\x1b[1;5C") },

  -- Standard Selection (Shift+Arrow = Select Char)
  { key = "LeftArrow", mods = "SHIFT", action = wezterm.action.SendString("\x1b[1;2D") },
  { key = "RightArrow", mods = "SHIFT", action = wezterm.action.SendString("\x1b[1;2C") },

  -- Word Selection (Ctrl+Shift+Arrow = Select Word)
  { key = "LeftArrow", mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x1b[1;6D") },
  { key = "RightArrow", mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x1b[1;6C") },
  { key = "UpArrow", mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x1b[1;6A") },
  { key = "DownArrow", mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x1b[1;6B") },

  -- Tab & Pane Alt/Ctrl Navigation
  { key = "LeftArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Down") },
  { key = "LeftArrow", mods = "CTRL|ALT", action = wezterm.action.ActivateTabRelative(-1) },
  { key = "RightArrow", mods = "CTRL|ALT", action = wezterm.action.ActivateTabRelative(1) },

  --  SMART CLIPBOARD LOGIC  --

  -- Smart Copy: If mouse selection exists, copy it. Else, tell Zsh to copy its region.
  {
    key = 'c',
    mods = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local selection_text = window:get_selection_text_for_pane(pane)
      if selection_text and #selection_text > 0 then
        window:perform_action(wezterm.action.CopyTo 'ClipboardAndPrimarySelection', pane)
        window:perform_action(wezterm.action.ClearSelection, pane)
      else
        window:perform_action(wezterm.action.SendString '\x1b_copy', pane)
      end
    end),
  },

  -- Smart Paste: Delegates to Zsh to handle the overwrite logic
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b_paste' },

  -- Smart Cut: Delegates to Zsh to copy and kill-region
  { key = 'x', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b_cut' },

  -- Smart Delete Selection: For Ctrl+Shift+Backspace
  { key = 'Backspace', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b_delsel' },

  -- Fallback Navigation
  { key = "Backspace", mods = "CTRL", action = wezterm.action.SendString("\x17") },
  { key = "Delete", mods = "CTRL", action = wezterm.action.SendString("\x1bd") },
  { key = "Enter", action = wezterm.action.SendString("\r") },
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\x1b\r") },
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
