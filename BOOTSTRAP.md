# Bootstrap Guide

Quick setup for a fresh machine (Linux/Raspberry Pi or Windows).

## Linux / Raspberry Pi

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Initialize and apply dotfiles
chezmoi init --apply https://github.com/jeff-barlow-spady/dot-files.git

# Install waffle (theme/font switcher)
mkdir -p "$HOME/.local/bin"
arch="$(uname -m)"
case "$arch" in
  aarch64|arm64) asset="waffle-linux-arm64" ;;
  x86_64|amd64)  asset="waffle-linux-amd64" ;;
  *) echo "Unsupported arch: $arch" ; exit 1 ;;
esac

url="$(curl -fsSL https://api.github.com/repos/Jeff-Barlow-Spady/waffle/releases/latest \
  | grep -oE '\"browser_download_url\":[^\\\"]*\"[^\\\"]*\"' \
  | cut -d'\"' -f4 \
  | grep \"/${asset}$\" \
  | head -n1)"

curl -fsSL -o "$HOME/.local/bin/waffle" "$url"
chmod +x "$HOME/.local/bin/waffle"

# Set theme and font (then apply changes)
waffle theme
chezmoi apply  # Apply theme changes
waffle font
chezmoi apply  # Apply font changes
```

## Windows

```powershell
# Install Scoop (if not already installed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
iwr -useb get.scoop.sh | iex

# Install core tools
scoop bucket add main
scoop install git chezmoi gum wezterm

# Initialize and apply dotfiles
chezmoi init --apply https://github.com/jeff-barlow-spady/dot-files.git

# Install waffle (theme/font switcher)
$arch = if ($env:PROCESSOR_ARCHITECTURE -match "ARM64") { "arm64" } else { "amd64" }
$asset = "waffle-windows-$arch.exe"
$api = "https://api.github.com/repos/Jeff-Barlow-Spady/waffle/releases/latest"
$release = Invoke-RestMethod -Uri $api
$match = $release.assets | Where-Object { $_.name -eq $asset } | Select-Object -First 1
$dest = "$env:USERPROFILE\scoop\shims\waffle.exe"
Invoke-WebRequest -Uri $match.browser_download_url -OutFile $dest

# Set theme and font (then apply changes)
waffle theme
chezmoi apply  # Apply theme changes
waffle font
chezmoi apply  # Apply font changes

# Optional: Install Windows tiling stack (komorebi, whkd, hitokage)
scoop install komorebi whkd flow-launcher hitokage
komorebic.exe start
whkd
hitokage
```

## After Setup

### Theme and Font Switching

After changing themes or fonts with waffle, always run `chezmoi apply` to apply the changes:

```bash
# Linux / Windows
waffle theme
chezmoi apply  # Required: Apply theme changes

waffle font
chezmoi apply  # Required: Apply font changes
```

### Updating Configs

To update configs after making changes to the dotfiles repository:

```bash
# Linux / Windows
chezmoi apply
```

### Available Configs

This dotfiles setup manages configs for:

**Cross-platform:**
- WezTerm (terminal)
- Starship (prompt)
- Fastfetch (system info)
- Neovim (editor)
- btop (system monitor)
- GitHub CLI (gh)
- LazyGit (git TUI)
- LazyDocker (docker TUI)

**Windows-only:**
- Komorebi (window tiler)
- whkd (hotkey daemon)
- Hitokage (status bar)
- BleachBit (cleanup tool)

**Linux-only:**
- Alacritty (terminal)
- Ghostty (terminal)
- Zellij (multiplexer)
- lxpanel (panel)
- wayfire (compositor)
- Neofetch (system info)


