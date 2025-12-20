local M = {}

function M.apply(wezterm, window, pane, h)
  -- 3-pane go workflow:
  -- right-top: shell (prints suggested commands)
  -- right-bottom: shell (prints suggested commands)
  h.split(wezterm, window, pane, 'Right', 0.40, h.hint_cmd({
    "[go] Suggested commands:",
    "  go test ./...",
    "  go test -run TestName ./...",
    "  go run .",
  }))
  local right = window:active_pane()
  h.split(wezterm, window, right, 'Down', 0.5, h.hint_cmd({
    "[go] Suggested commands:",
    "  golangci-lint run   (if installed)",
    "  go vet ./...",
    "  go test ./...",
  }))
  h.activate_dir(wezterm, window, window:active_pane(), 'Left')
end

return M


