local wezterm = require 'wezterm'
local act = wezterm.action

local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- =============================================================
--  APPEARANCE & SYSTEM
-- =============================================================
config.color_scheme = "Nord (Gogh)"
config.font = wezterm.font("JetBrains Mono", { weight = "Bold" })
config.font_size = 10

config.window_background_opacity = 0.0
config.text_background_opacity = 0.0
config.window_decorations = "RESIZE"
config.window_padding = { left = 7, right = 5, top = 2, bottom = 0 }

config.enable_tab_bar = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.automatically_reload_config = true
config.window_close_confirmation = "AlwaysPrompt"
config.skip_close_confirmation_for_processes_named = {
  "bash", "sh", "zsh", "fish", "tmux", "nu", "cmd.exe", "pwsh", "powershell"
}
config.check_for_updates = false
config.enable_wayland = false
config.adjust_window_size_when_changing_font_size = false
config.default_cursor_style = "BlinkingUnderline"
config.cursor_thickness = "1px"

-- =============================================================
--  KEYS & BINDINGS
-- =============================================================
config.keys = {
  -- 1. SMART COPY (Hybrid: Try Mouse Select -> Fallback to Zsh Signal)
  {
    key = 'c',
    mods = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local selection_text = window:get_selection_text_for_pane(pane)
      if selection_text and #selection_text > 0 then
        window:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', pane)
        window:perform_action(act.ClearSelection, pane)
        window:perform_action(act.SendString '\x1b[1;21~', pane) -- Clear Zsh highlight too
      else
        window:perform_action(act.SendString '\x1b[1;20~', pane)
      end
    end),
  },

  -- 2. SMART CUT (Hybrid: Try Mouse Select -> Fallback to Zsh Signal)
  {
    key = 'x',
    mods = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local selection_text = window:get_selection_text_for_pane(pane)
      if selection_text and #selection_text > 0 then
         window:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', pane)
         window:perform_action(act.SendString '\x1b[1;23~', pane) -- Just delete in Zsh
      else
         window:perform_action(act.SendString '\x1b[1;24~', pane) -- Trigger Cut Widget
      end
    end),
  },

  -- 3. UNIVERSAL PASTE (Delete selection first, then paste)
  {
    key = 'v',
    mods = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(act.SendString '\x1b[1;21~', pane)
      window:perform_action(act.PasteFrom 'Clipboard', pane)
    end),
  },

  -- 4. DELETE SELECTION ONLY
  { key = 'Backspace', mods = 'CTRL|SHIFT', action = act.SendString '\x1b[1;23~' },

  -- 5. EDITING & UNDO/REDO
  { key = 'z', mods = 'CTRL|SHIFT', action = act.SendString '\x1a' }, -- Send ^Z (Mapped to Undo in Zsh)
  { key = '_', mods = 'CTRL|SHIFT', action = act.SendString '\x1f' }, -- Send ^_ (Redo)
  { key = 'Enter', mods = 'SHIFT', action = act.SendString '\x0a' },  -- Send ^J (Soft Newline)
  
  -- 6. NAVIGATION & SELECTION SIGNALS
  -- WezTerm defaults usually handle these, but we enforce them for Zsh consistency
  { key = 'LeftArrow', mods = 'CTRL', action = act.SendString "\x1b[1;5D" },
  { key = 'RightArrow', mods = 'CTRL', action = act.SendString "\x1b[1;5C" },
  { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = act.SendString "\x1b[1;6D" },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.SendString "\x1b[1;6C" },
  { key = 'LeftArrow', mods = 'SHIFT', action = act.SendString "\x1b[1;2D" },
  { key = 'RightArrow', mods = 'SHIFT', action = act.SendString "\x1b[1;2C" },
  { key = 'Home', mods = 'SHIFT', action = act.SendString "\x1b[1;2H" },
  { key = 'End', mods = 'SHIFT', action = act.SendString "\x1b[1;2F" },
  { key = 'a', mods = 'CTRL', action = act.SendString "\x01" }, -- Ctrl+A (Select All)

  -- 7. FONT RESIZING
  { key = '+', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize },

  -- 8. PANE & TAB MANAGEMENT
  { key = "t", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "CTRL", action = act.CloseCurrentTab({ confirm = true }) },
  { key = "x", mods = "ALT", action = act.CloseCurrentPane({ confirm = true }) },
  
  -- Splits
  { key = "Backslash", mods = "CTRL", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "|", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  
  -- Pane Navigation (Alt + Arrow / Ctrl+Shift+HJKL)
  { key = "LeftArrow", mods = "ALT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "ALT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "ALT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "ALT", action = act.ActivatePaneDirection("Down") },
  { key = "h", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },

  -- Tab Navigation
  { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
  { key = "LeftArrow", mods = "CTRL|ALT", action = act.ActivateTabRelative(-1) },
  { key = "RightArrow", mods = "CTRL|ALT", action = act.ActivateTabRelative(1) },

  -- Apps
  { key = "f", mods = "SHIFT|SUPER", action = act.SpawnCommandInNewWindow { args = { "fresh" } } },
}

config.hyperlink_rules = {
  { regex = [=[ \(\w+://\S+\) ]=], format = "$1", highlight = 1 },
  { regex = [=[ \[\[\w+://\S+\]\] ]=], format = "$1", highlight = 1 },
  { regex = [=[ \{\w+://\S+\} ]=], format = "$1", highlight = 1 },
  { regex = [=[ <\w+://\S+> ]=],    format = "$1", highlight = 1 },
}

return config