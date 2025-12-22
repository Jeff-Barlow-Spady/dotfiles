#!/usr/bin/env bash
# Bootstrap script for a fresh Linux machine (incl. Raspberry Pi).
# Installs: git, chezmoi, webi, gum, and common CLI tools (ripgrep/fzf/yq/etc).
#
# Usage:
#   REPO_URL="https://github.com/YOUR_USERNAME/dotfiles.git" ./setup.sh
# or:
#   ./setup.sh --repo "https://github.com/YOUR_USERNAME/dotfiles.git"

set -euo pipefail

REPO_URL="${REPO_URL:-}"
WAFFLE_REPO="${WAFFLE_REPO:-Jeff-Barlow-Spady/waffle}"
INSTALL_WAFFLE="${INSTALL_WAFFLE:-1}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO_URL="${2:-}"
      shift 2
      ;;
    --no-waffle)
      INSTALL_WAFFLE="0"
      shift 1
      ;;
    --waffle-repo)
      WAFFLE_REPO="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

log() { printf "%s\n" "$*"; }
need() { command -v "$1" >/dev/null 2>&1; }
have_apt() { need apt-get; }
have_snap() { need snap; }
have_curl() { need curl; }

apt_install() {
  have_apt || return 1
  sudo apt-get update -y
  sudo apt-get install -y "$@"
}

snap_install() {
  have_snap || return 1
  sudo snap install "$@"
}

log "🍯 Waffle Dotfiles Bootstrap (Linux)"
log "==================================="

# ---- base packages (Debian/Ubuntu/Pi OS) ----
if have_apt; then
  apt_install git curl ca-certificates unzip
fi

# ---- webi (webinstall.dev) ----
if ! need webi; then
  log "Installing webi..."
  curl -fsSL https://webi.sh/webi | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

# ---- chezmoi ----
if ! need chezmoi; then
  log "Installing chezmoi..."
  # Prefer webi, then apt, then snap, then official install script
  if need webi; then
    webi chezmoi || true
  fi
  if ! need chezmoi; then
    apt_install chezmoi || true
  fi
  if ! need chezmoi; then
    snap_install chezmoi --classic || true
  fi
  if ! need chezmoi; then
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  fi
  export PATH="$HOME/.local/bin:$PATH"
fi

# ---- gum (for waffle UI) ----
if ! need gum; then
  log "Installing gum..."
  # Prefer webi, then apt, then snap
  if need webi; then
    webi gum || true
  fi
  if ! need gum; then
    apt_install gum || true
  fi
  if ! need gum; then
    snap_install gum || true
  fi
  export PATH="$HOME/.local/bin:$PATH"
fi

# ---- common CLIs (your preferred webi installs) ----
log "Installing common CLI tools with webi (idempotent)..."
webi yq ripgrep fzf neofetch nerdfonts || true
webi jq fd bat zoxide starship || true

# Fallback installs for common tools (apt/snap), best-effort
if have_apt; then
  apt_install ripgrep fzf jq || true
fi

install_waffle_linux() {
  # Installs waffle from GitHub releases to ~/.local/bin/waffle
  # Requires: curl
  if [[ "$INSTALL_WAFFLE" != "1" ]]; then
    log "Skipping waffle install (--no-waffle)."
    return 0
  fi
  if ! have_curl; then
    log "curl not found; cannot install waffle automatically."
    return 0
  fi

  local os arch asset api_url url dest
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"

  case "$arch" in
    aarch64|arm64) arch="arm64" ;;
    x86_64|amd64) arch="amd64" ;;
  esac

  asset="waffle-${os}-${arch}"
  api_url="https://api.github.com/repos/${WAFFLE_REPO}/releases/latest"

  log "Installing waffle from GitHub Releases (${WAFFLE_REPO})..."
  log "  - target asset: ${asset}"

  # Extract the browser_download_url for the desired asset without requiring jq.
  url="$(curl -fsSL "$api_url" | grep -oE '"browser_download_url":[^"]*"[^"]*"' | cut -d'"' -f4 | grep "/${asset}$" | head -n1 || true)"
  if [[ -z "$url" ]]; then
    log "⚠️  Could not find release asset '${asset}' in latest release."
    log "    You can install manually from: https://github.com/${WAFFLE_REPO}/releases"
    return 0
  fi

  mkdir -p "$HOME/.local/bin"
  dest="$HOME/.local/bin/waffle"
  curl -fsSL -o "$dest" "$url"
  chmod +x "$dest"
  log "✅ Installed waffle to $dest"
}

log ""
if [[ -n "$REPO_URL" ]]; then
  log "Initializing chezmoi from: $REPO_URL"
  # If already initialized, just apply; otherwise init
  if [[ -d "$HOME/.local/share/chezmoi" ]] || [[ -n "${CHEZMOI_SOURCE_DIR:-}" ]]; then
    log "Chezmoi already initialized, applying changes..."
    chezmoi apply
  else
    chezmoi init --apply "$REPO_URL"
  fi
else
  log "REPO_URL not provided."
  log "Run:"
  log "  chezmoi init --apply https://github.com/jeff-barlow-spady/dotfiles.git"
fi

log ""
install_waffle_linux

log ""
log "✅ Bootstrap complete."
log "Next:"
log "  - Install WezTerm (optional on Linux) via your package manager"
log "  - Run: waffle theme"

