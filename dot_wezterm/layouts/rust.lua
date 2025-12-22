local M = {}

function M.apply(wezterm, window, pane, h)
  -- 3-pane rust layout:
  -- left: editor/shell (current pane)
  -- right-top: shell
  -- right-bottom: shell
  h.split(wezterm, window, pane, 'Right', 0.40)
  local right = window:active_pane()
  h.split(wezterm, window, right, 'Down', 0.5)
  h.activate_dir(wezterm, window, window:active_pane(), 'Left')
end

return M


