local M = {}

function M.apply(wezterm, window, pane, h)
  -- 3-pane web workflow:
  -- right-top: shell (prints suggested commands)
  -- right-bottom: shell (prints suggested commands)
  h.split(wezterm, window, pane, 'Right', 0.40, h.hint_cmd({
    "[web] Suggested commands:",
    "  pnpm dev     (or npm run dev / yarn dev)",
    "  pnpm lint    (or npm run lint / yarn lint)",
  }))
  local right = window:active_pane()
  h.split(wezterm, window, right, 'Down', 0.5, h.hint_cmd({
    "[web] Suggested commands:",
    "  pnpm test    (or npm test / yarn test)",
    "  pnpm test -w",
  }))
  h.activate_dir(wezterm, window, window:active_pane(), 'Left')
end

return M


