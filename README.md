# Dotfiles Setup

This repository contains dotfiles managed with chezmoi, including themes, fonts, and configurations for WezTerm, Komorebi, Hitokage, and more.

## Initial Setup on a New Machine

### Bootstrap scripts (recommended)

These scripts install prerequisites and then run `chezmoi init --apply`.

For a copy/paste command checklist, see `BOOTSTRAP.md`.

**Linux / Raspberry Pi:**

```bash
# from a cloned repo:
REPO_URL="https://github.com/YOUR_USERNAME/dotfiles.git" ./setup.sh

# or download & run directly once this repo is public:
# curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/setup.sh | REPO_URL="https://github.com/YOUR_USERNAME/dotfiles.git" bash
```

**Windows (PowerShell):**

```powershell
# from a cloned repo:
$env:REPO_URL="https://github.com/YOUR_USERNAME/dotfiles.git"; .\setup.ps1

# or download & run directly once this repo is public:
# iwr -useb https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/setup.ps1 | iex
```

**Windows tiling (separate, after base setup):**

```powershell
.\windows-tiling.ps1
```

### Prerequisites

**Windows:**
- [chezmoi](https://www.chezmoi.io/install/) - `scoop install chezmoi` or `choco install chezmoi`
- [WezTerm](https://wezterm.com/install/windows.html) - `scoop install wezterm` or `winget install wez.wezterm`
- [Komorebi](https://github.com/LGUG2Z/komorebi) - `scoop install komorebi`
- [whkd](https://github.com/LGUG2Z/whkd) - `scoop install whkd`
- [Hitokage](https://github.com/codyduong/hitokage) - Status bar for Komorebi
- [gum](https://github.com/charmbracelet/gum) - For waffle CLI: `scoop install gum`
- [Go](https://go.dev/dl/) - For building waffle: `scoop install go`

**Linux (any distro):**
- chezmoi - `sudo apt install chezmoi` or [install script](https://www.chezmoi.io/install/)
- WezTerm or Ghostty - Terminal emulator (works on any distro)
- Zellij - Terminal multiplexer: `cargo install zellij` or package manager
- Neovim - Editor (works on any distro)
- btop - System monitor (optional)
- gum - For waffle CLI
- Go - For building waffle

**Linux (GNOME/Ubuntu only - optional):**
- GNOME desktop environment (for `gnome.sh` theme scripts)
- Tophat GNOME extension (for `tophat.sh` scripts)
- Note: GNOME-specific scripts are optional; core tools work on any Linux distro

### Installation Steps

1. **Initialize chezmoi from this repository:**
   ```bash
   # Replace with your actual GitHub repo URL
   chezmoi init --apply https://github.com/YOUR_USERNAME/dotfiles.git
   ```

2. **Build and install waffle CLI:**
   ```bash
   cd ~/path/to/dotfiles/waffle
   go build -o waffle .
   # Add to PATH or copy to ~/bin/ or /usr/local/bin/
   ```

3. **Set initial theme and font:**
   ```bash
   waffle theme  # Select a theme
   waffle font   # Select a font
   ```

4. **Windows-specific: Start services**
   ```powershell
   # Start Komorebi
   komorebic.exe start
   
   # Start whkd (hotkey daemon)
   whkd
   
   # Start Hitokage (status bar)
   hitokage
   ```

## Directory Structure

- `dot_config/` - Configuration files (templated)
- `themes/` - Theme assets (alacritty, zellij, nvim, btop, etc.)
- `.local/share/dotfiles/themes/` - Theme files for WezTerm (Option B path)
- `komorebi/` - Komorebi-specific configs
- `.wezterm.lua` + `.wezterm/` - WezTerm entrypoint + modular config (layouts live here)

## How It Works

1. **Waffle CLI** updates chezmoi data (`.chezmoidata.yaml`) with selected theme/font:
   - Linux default: `~/.local/share/chezmoi/.chezmoidata.yaml` (or `$XDG_DATA_HOME/chezmoi/.chezmoidata.yaml`)
   - Windows default: `%LOCALAPPDATA%\\chezmoi\\.chezmoidata.yaml`
   - Override: `CHEZMOI_DATA_DIR`
2. **Chezmoi templates** read from `.chezmoi.current_theme` and `.chezmoi.current_font`
3. **OS conditionals** ensure only relevant configs are generated:
   - Windows: WezTerm + Komorebi + Hitokage + whkd
   - Linux: WezTerm + Zellij + Ghostty + Neovim + btop
   - Linux (GNOME): Additional desktop theming via `gnome.sh` scripts (optional)

## WezTerm Layouts (Zellij-like)

The language/task-specific pane layouts are implemented as **Lua modules** under:
- `~/.wezterm/layouts/` (chezmoi source: `chezmoi/dot_wezterm/layouts/`)

Default keybindings:
- **Pane nav**: `ALT` + arrow keys
- **Leader**: `CTRL+a`
- **Layouts**:
  - `CTRL+a d` → dotnet
  - `CTRL+a p` → python-datascience
  - `CTRL+a w` → web-typescript
  - `CTRL+a g` → golang
  - `CTRL+a r` → rust

If you previously had a `~/.config/wezterm/wezterm.lua` that referenced `WAFFLE_THEME` env vars, that was an older config style; this repo’s source of truth is now `~/.wezterm.lua` + `~/.wezterm/` and theme selection comes from chezmoi data (`current_theme/current_font`).

**Important**: To avoid confusion, remove or rename any existing `~/.config/wezterm/wezterm.lua` so you only have one active configuration entrypoint. This dotfiles setup manages `~/.wezterm.lua`.

## Windows Paths

On Windows, chezmoi will:
- Detect OS as `windows` (`.chezmoi.os == "windows"`)
- Apply configs to appropriate Windows locations:
  - WezTerm: `%USERPROFILE%\.wezterm.lua` (or `%USERPROFILE%\.config\wezterm\wezterm.lua`)
  - Komorebi: `%APPDATA%\komorebi\komorebi.json`
  - Hitokage: `%USERPROFILE%\.config\hitokage\init.lua`
  - whkd: `%USERPROFILE%\.config\whkdrc`
  - Themes: `%LOCALAPPDATA%\dotfiles\themes\` (Option B path)

## Linux Compatibility

**Works on any Linux distro:**
- ✅ WezTerm terminal configuration
- ✅ Zellij multiplexer configuration  
- ✅ Ghostty terminal configuration
- ✅ Neovim editor configuration
- ✅ btop system monitor themes
- ✅ Waffle CLI theme/font switching

**GNOME/Ubuntu specific (optional):**
- ⚠️ `gnome.sh` scripts - Use `gsettings` to theme GNOME desktop (only works on GNOME)
- ⚠️ `tophat.sh` scripts - Configure Tophat GNOME extension (only works with Tophat installed)

**Note**: The GNOME-specific scripts in theme directories are optional. If you're not on GNOME, they'll simply be ignored. All core terminal/editor tools work on any Linux distribution (Arch, Fedora, Debian, etc.).

## Troubleshooting

- **Themes not found**: Ensure `~/.local/share/dotfiles/themes/` exists and contains theme directories
- **OS detection issues**: Check `chezmoi data` to see detected OS
- **Templates not applying**: Run `chezmoi apply -v` to see what's happening
- **GNOME scripts fail**: This is expected if you're not on GNOME - they're optional

