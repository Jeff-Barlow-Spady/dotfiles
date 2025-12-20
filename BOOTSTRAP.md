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
REPO_URL="https://github.com/jeff-barlow-spady/dot-files.git" ./setup.sh
```

What it does:
- Uses **webi** first (`webinstall.dev`)
- Falls back to **apt** (and **snap** if present) for core tools
- Runs `chezmoi init --apply`

### Option B: Official chezmoi installer + apply (minimal)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

chezmoi init --apply https://github.com/jeff-barlow-spady/dot-files.git
```

### Pi: install waffle

#### Option A (recommended): download from GitHub Releases on the Pi

```bash
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

waffle theme
waffle font
```

#### Option B: copy a prebuilt from your dev machine

```bash
# on your dev machine (build creates waffle-linux-arm64)
cd /home/toasty/CONFIGS/waffle
make build-linux-arm64
scp waffle-linux-arm64 pi@PI_HOST_OR_IP:/home/pi/.local/bin/waffle

# on the pi
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

- Skip waffle install (if you want to install it yourself):

```powershell
.\setup.ps1 -NoWaffle
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


