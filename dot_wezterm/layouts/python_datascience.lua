local M = {}

function M.apply(wezterm, window, pane, h)
  -- 3-pane python workflow:
  -- right-top: shell (prints suggested commands)
  -- right-bottom: shell (prints suggested commands)
  h.split(wezterm, window, pane, 'Right', 0.40, h.hint_cmd({
    "[python] Suggested commands:",
    "  ipython",
    "  python",
    "  uv run python -q",
  }))
  local right = window:active_pane()
  h.split(wezterm, window, right, 'Down', 0.5, h.hint_cmd({
    "[python] Suggested commands:",
    "  pytest -q",
    "  python -m pytest -q",
    "  pytest -q --maxfail=1",
  }))
  h.activate_dir(wezterm, window, window:active_pane(), 'Left')
end

return M


