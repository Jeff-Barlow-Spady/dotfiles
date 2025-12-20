# Bootstrap Commands (copy/paste)

This is the “fresh machine” checklist to get from **nothing → working dotfiles**, including a Raspberry Pi test box and Windows (Scoop-first).

## Linux / Raspberry Pi

### Option A: Run `setup.sh` from a clone (recommended)

```bash
# 0) clone your repo
git clone https://github.com/YOUR_USERNAME/dotfiles.git
cd dotfiles/chezmoi

# 1) bootstrap prereqs + chezmoi apply
chmod +x setup.sh
REPO_URL="https://github.com/YOUR_USERNAME/dotfiles.git" ./setup.sh
```

What it does:
- Uses **webi** first (`webinstall.dev`)
- Falls back to **apt** (and **snap** if present) for core tools
- Runs `chezmoi init --apply`

### Option B: Official chezmoi installer + apply (minimal)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

chezmoi init --apply https://github.com/YOUR_USERNAME/dotfiles.git
```

### Pi: install waffle binary (recommended: copy the prebuilt)

From your dev machine:

```bash
# build (creates waffle-linux-arm64)
cd /home/toasty/CONFIGS/waffle
make build-linux-arm64

# copy to pi
scp waffle-linux-arm64 pi@PI_HOST_OR_IP:/home/pi/.local/bin/waffle
```

On the Pi:

```bash
chmod +x "$HOME/.local/bin/waffle"
waffle theme
waffle font
```

## Windows (Scoop-first)

### Base bootstrap (installs Scoop, git, chezmoi, gum, wezterm, CLI tools, languages)

From a clone:

```powershell
git clone https://github.com/YOUR_USERNAME/dotfiles.git
cd dotfiles\chezmoi
$env:REPO_URL="https://github.com/YOUR_USERNAME/dotfiles.git"
.\setup.ps1
```

### Base bootstrap switches

- Skip WezTerm install (if you already have it):

```powershell
.\setup.ps1 -NoWezTerm
```

- Core tools only (skip CLI tools + languages):

```powershell
.\setup.ps1 -NoCliTools -NoLanguages
```

- Skip languages/toolchains:

```powershell
.\setup.ps1 -NoLanguages
```

- Skip CLI tools:

```powershell
.\setup.ps1 -NoCliTools
```

### Windows tiling (separate script)

Installs: **komorebi**, **whkd**, **flow-launcher**, **hitokage**

```powershell
.\windows-tiling.ps1
```

Switches:

- No Flow Launcher:

```powershell
.\windows-tiling.ps1 -NoFlowLauncher
```

- No Hitokage:

```powershell
.\windows-tiling.ps1 -NoHitokage
```

### After setup

```powershell
# apply again any time you tweak configs
chezmoi apply

# start tiling stack
komorebic.exe start
whkd
hitokage
```


