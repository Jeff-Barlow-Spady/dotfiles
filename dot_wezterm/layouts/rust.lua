local M = {}

function M.apply(wezterm, window, pane, h)
  -- 3-pane rust workflow:
  -- right-top: shell (prints suggested commands)
  -- right-bottom: shell (prints suggested commands)
  h.split(wezterm, window, pane, 'Right', 0.40, h.hint_cmd({
    "[rust] Suggested commands:",
    "  cargo test",
    "  cargo run",
    "  cargo fmt",
  }))
  local right = window:active_pane()
  h.split(wezterm, window, right, 'Down', 0.5, h.hint_cmd({
    "[rust] Suggested commands:",
    "  cargo test",
    "  cargo clippy   (if installed)",
    "  cargo watch -x test   (if installed)",
  }))
  h.activate_dir(wezterm, window, window:active_pane(), 'Left')
end

return M


