<#  Bootstrap script for a fresh Windows machine (PowerShell).
    Uses Scoop (preferred) to install git/chezmoi/gum/wezterm and common dev tools.
    Languages are NOT installed by default (use -Languages to opt-in).

    Usage:
      $env:REPO_URL="https://github.com/YOUR_USERNAME/dotfiles.git"; .\setup.ps1
      .\setup.ps1 -RepoUrl "https://github.com/YOUR_USERNAME/dotfiles.git"
      .\setup.ps1 -RepoUrl "..." -Languages  # Include language toolchains
#>

param(
  [string]$RepoUrl = $env:REPO_URL,
  [switch]$NoCore,
  [switch]$NoCliTools,
  [switch]$Languages,
  [switch]$NoWezTerm,
  [switch]$NoWaffle,
  [string]$WaffleRepo = "Jeff-Barlow-Spady/waffle"
)

Write-Host "🍯 Waffle Dotfiles Bootstrap (Windows)" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

function Have($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# Install Scoop if missing
if (-not (Have "scoop")) {
  Write-Host "Installing Scoop..." -ForegroundColor Yellow
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
  iwr -useb get.scoop.sh | iex
}

# Buckets (safe to re-run)
scoop bucket add main 2>$null | Out-Null
scoop bucket add extras 2>$null | Out-Null

if (-not $NoCore) {
  Write-Host "Installing core tools..." -ForegroundColor Yellow
  $core = @("git","chezmoi","gum")
  if (-not $NoWezTerm) { $core += "wezterm" }
  scoop install @core | Out-Null
} else {
  Write-Host "Skipping core tools (-NoCore)" -ForegroundColor Yellow
}

if (-not $NoCliTools) {
  Write-Host "Installing common CLI tools..." -ForegroundColor Yellow
  scoop install ripgrep fd fzf jq yq bat starship zoxide neovim | Out-Null
} else {
  Write-Host "Skipping CLI tools (-NoCliTools)" -ForegroundColor Yellow
}

if ($Languages) {
  Write-Host "Installing dev languages/toolchains..." -ForegroundColor Yellow
  Write-Host "  Note: Python is included here. If you use a Python install manager (pyenv, etc.)," -ForegroundColor Yellow
  Write-Host "  you may want to skip this section and install languages manually." -ForegroundColor Yellow
  scoop install go nodejs python dotnet-sdk rustup | Out-Null
} else {
  Write-Host "Skipping languages/toolchains (use -Languages to install)" -ForegroundColor Yellow
  Write-Host "  This allows you to use your preferred install managers (e.g., pyenv for Python)" -ForegroundColor Cyan
}

Write-Host ""
if ($RepoUrl) {
  Write-Host "Initializing chezmoi from $RepoUrl ..." -ForegroundColor Yellow
  # If already initialized, just apply; otherwise init
  $chezmoiSource = "$env:LOCALAPPDATA\chezmoi"
  if ((Test-Path $chezmoiSource) -or $env:CHEZMOI_SOURCE_DIR) {
    Write-Host "Chezmoi already initialized, applying changes..." -ForegroundColor Yellow
    chezmoi apply
  } else {
    chezmoi init --apply $RepoUrl
  }
} else {
  Write-Host "Repo URL not provided." -ForegroundColor Yellow
  Write-Host "Run:" -ForegroundColor Yellow
  Write-Host "  chezmoi init --apply https://github.com/YOUR_USERNAME/dotfiles.git"
}

function Install-Waffle {
  param(
    [string]$Repo
  )

  if ($NoWaffle) {
    Write-Host "Skipping waffle install (-NoWaffle)" -ForegroundColor Yellow
    return
  }

  # Determine arch
  $arch = "amd64"
  if ($env:PROCESSOR_ARCHITECTURE -match "ARM64") { $arch = "arm64" }
  $asset = "waffle-windows-$arch.exe"

  Write-Host ""
  Write-Host "Installing waffle from GitHub Releases ($Repo)..." -ForegroundColor Yellow
  Write-Host "  - target asset: $asset" -ForegroundColor Yellow

  $api = "https://api.github.com/repos/$Repo/releases/latest"
  try {
    $release = Invoke-RestMethod -Uri $api -Headers @{ "User-Agent" = "waffle-bootstrap" }
    $match = $release.assets | Where-Object { $_.name -eq $asset } | Select-Object -First 1
    if (-not $match) {
      Write-Host "⚠️  Asset not found in latest release: $asset" -ForegroundColor Yellow
      Write-Host "    Install manually from: https://github.com/$Repo/releases" -ForegroundColor Yellow
      return
    }

    $shimDir = Join-Path $env:USERPROFILE "scoop\shims"
    if (-not (Test-Path $shimDir)) {
      # Scoop should have created it; fallback to ~/.local/bin-ish
      $shimDir = Join-Path $env:USERPROFILE ".local\bin"
    }
    New-Item -ItemType Directory -Force -Path $shimDir | Out-Null

    $dest = Join-Path $shimDir "waffle.exe"
    Invoke-WebRequest -Uri $match.browser_download_url -OutFile $dest
    Write-Host "✅ Installed waffle to $dest" -ForegroundColor Green
  } catch {
    Write-Host "⚠️  Failed to install waffle automatically: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "    Install manually from: https://github.com/$Repo/releases" -ForegroundColor Yellow
  }
}

Install-Waffle -Repo $WaffleRepo

Write-Host ""
Write-Host "✅ Bootstrap complete." -ForegroundColor Green
Write-Host "Next:" -ForegroundColor Cyan
Write-Host "  - Run: waffle theme"
Write-Host "  - For Windows tiling apps (komorebi/whkd/flow-launcher/hitokage), run: .\\windows-tiling.ps1"

