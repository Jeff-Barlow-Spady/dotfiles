<#  Windows tiling bootstrap (separate from base setup).
    Installs: komorebi, whkd, flow-launcher, hitokage via Scoop.

    Usage:
      .\windows-tiling.ps1
      .\windows-tiling.ps1 -NoFlowLauncher
#>

param(
  [switch]$NoFlowLauncher,
  [switch]$NoHitokage
)

Write-Host "🪟 Waffle Windows Tiling Bootstrap" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

function Have($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

if (-not (Have "scoop")) {
  Write-Host "Scoop not found. Run setup.ps1 first." -ForegroundColor Red
  exit 1
}

scoop bucket add main 2>$null | Out-Null
scoop bucket add extras 2>$null | Out-Null

Write-Host "Installing tiling apps..." -ForegroundColor Yellow
$apps = @("komorebi","whkd")
if (-not $NoFlowLauncher) { $apps += "flow-launcher" }
if (-not $NoHitokage) { $apps += "hitokage" }
scoop install @apps | Out-Null

Write-Host ""
Write-Host "✅ Installed." -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  - Apply your dotfiles: chezmoi apply"
Write-Host "  - Start komorebi: komorebic.exe start"
Write-Host "  - Start whkd: whkd"
Write-Host "  - Start hitokage: hitokage"


