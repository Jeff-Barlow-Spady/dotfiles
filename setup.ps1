<#  Bootstrap script for a fresh Windows machine (PowerShell).
    Uses Scoop (preferred) to install git/chezmoi/gum/wezterm and common dev tools.

    Usage:
      $env:REPO_URL="https://github.com/YOUR_USERNAME/dotfiles.git"; .\setup.ps1
      .\setup.ps1 -RepoUrl "https://github.com/YOUR_USERNAME/dotfiles.git"
#>

param(
  [string]$RepoUrl = $env:REPO_URL,
  [switch]$NoCore,
  [switch]$NoCliTools,
  [switch]$NoLanguages,
  [switch]$NoWezTerm
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

if (-not $NoLanguages) {
  Write-Host "Installing dev languages/toolchains..." -ForegroundColor Yellow
  scoop install go nodejs python dotnet-sdk rustup | Out-Null
} else {
  Write-Host "Skipping languages/toolchains (-NoLanguages)" -ForegroundColor Yellow
}

Write-Host ""
if ($RepoUrl) {
  Write-Host "Initializing chezmoi from $RepoUrl ..." -ForegroundColor Yellow
  chezmoi init --apply $RepoUrl
} else {
  Write-Host "Repo URL not provided." -ForegroundColor Yellow
  Write-Host "Run:" -ForegroundColor Yellow
  Write-Host "  chezmoi init --apply https://github.com/YOUR_USERNAME/dotfiles.git"
}

Write-Host ""
Write-Host "✅ Bootstrap complete." -ForegroundColor Green
Write-Host "Next:" -ForegroundColor Cyan
Write-Host "  - Install waffle (recommended: download from releases) then run: waffle theme"
Write-Host "  - For Windows tiling apps (komorebi/whkd/flow-launcher/hitokage), run: .\\windows-tiling.ps1"

