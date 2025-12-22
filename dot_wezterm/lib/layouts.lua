local M = {}

local layouts = {
  dotnet = require('layouts.dotnet'),
  ['python-datascience'] = require('layouts.python_datascience'),
  ['web-typescript'] = require('layouts.web_typescript'),
  golang = require('layouts.golang'),
  rust = require('layouts.rust'),
}

local function is_windows(wezterm)
  return wezterm.target_triple and wezterm.target_triple:find('windows') ~= nil
end


function M.split(wezterm, window, pane, direction, size)
  local action = wezterm.action.SplitPane({
    direction = direction,
    size = size,
  })
  window:perform_action(action, pane)
  return window:active_pane()
end

function M.activate_dir(wezterm, window, pane, direction)
  window:perform_action(wezterm.action.ActivatePaneDirection(direction), pane)
  return window:active_pane()
end

function M.register(wezterm)
  for name, mod in pairs(layouts) do
    wezterm.on('waffle:layout:' .. name, function(window, pane)
      mod.apply(wezterm, window, pane, M)
    end)
  end
end

function M.keys(wezterm)
  return {
    -- Layout launchers (leader-based, zellij-ish)
    { key = 'd', mods = 'LEADER', action = wezterm.action.EmitEvent('waffle:layout:dotnet') },
    { key = 'p', mods = 'LEADER', action = wezterm.action.EmitEvent('waffle:layout:python-datascience') },
    { key = 'w', mods = 'LEADER', action = wezterm.action.EmitEvent('waffle:layout:web-typescript') },
    { key = 'g', mods = 'LEADER', action = wezterm.action.EmitEvent('waffle:layout:golang') },
    { key = 'r', mods = 'LEADER', action = wezterm.action.EmitEvent('waffle:layout:rust') },
  }
end

return M


