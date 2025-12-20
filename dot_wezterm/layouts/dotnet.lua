local M = {}

function M.apply(wezterm, window, pane, h)
  -- 3-pane dotnet workflow:
  -- left: editor/shell (current pane)
  -- right-top: shell (prints suggested commands)
  -- right-bottom: shell (prints suggested commands)
  h.split(wezterm, window, pane, 'Right', 0.35, h.hint_cmd({
    "[dotnet] Suggested commands:",
    "  dotnet watch run",
    "  dotnet test -w",
  }))
  local right = window:active_pane()
  h.split(wezterm, window, right, 'Down', 0.5, h.hint_cmd({
    "[dotnet] Suggested commands:",
    "  dotnet test -w",
    "  dotnet watch test",
  }))
  h.activate_dir(wezterm, window, window:active_pane(), 'Left')
end

return M


