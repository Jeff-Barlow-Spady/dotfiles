local M = {}

-- Load a per-theme wezterm.lua file (generated/stored in Option B theme dir)
local function load_theme_file(wezterm, theme_dir, theme_name)
  local theme_path = string.format('%s/%s/wezterm.lua', theme_dir, theme_name)
  local chunk, err = loadfile(theme_path)
  if not chunk then
    wezterm.log_error('Failed to load theme file: ' .. tostring(err))
    return {}
  end

  local ok, data = pcall(chunk)
  if not ok then
    wezterm.log_error('Failed to execute theme file: ' .. tostring(data))
    return {}
  end

  return data or {}
end

function M.apply(config, theme_dir, theme_name)
  local wezterm = require 'wezterm'
  local theme = load_theme_file(wezterm, theme_dir, theme_name)

  if theme.color_schemes and theme.color_schemes[theme_name] then
    config.color_schemes = theme.color_schemes
    config.color_scheme = theme_name
  else
    wezterm.log_error('Color scheme not found for theme: ' .. tostring(theme_name))
  end
end

return M


