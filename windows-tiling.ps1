<#  Windows tiling bootstrap (separate from base setup).
    Installs: komorebi, whkd, flow-launcher via Scoop.
    Installs: hitokage via direct MSI download (young project, use with caution).

    Usage:
      .\windows-tiling.ps1
      .\windows-tiling.ps1 -NoFlowLauncher
      .\windows-tiling.ps1 -NoHitokage
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

Write-Host "Installing tiling apps via Scoop..." -ForegroundColor Yellow
$apps = @("komorebi","whkd")
if (-not $NoFlowLauncher) { $apps += "flow-launcher" }

foreach ($app in $apps) {
  if (Have $app) {
    Write-Host "  ✅ $app is already installed" -ForegroundColor Green
  } else {
    Write-Host "  Installing $app..." -ForegroundColor Cyan
    scoop install $app 2>&1 | Out-Null
    if (Have $app) {
      Write-Host "  ✅ $app installed successfully" -ForegroundColor Green
    } else {
      Write-Host "  ⚠️  $app installation may have failed - command not found" -ForegroundColor Yellow
    }
  }
}

# Install hitokage directly from MSI (young project, not in Scoop)
if (-not $NoHitokage) {
  Write-Host ""
  Write-Host "Installing hitokage (status bar)..." -ForegroundColor Yellow
  Write-Host "⚠️  WARNING: Hitokage is a very young project - use with caution" -ForegroundColor Yellow
  Write-Host "    This installs the nightly build which may be unstable" -ForegroundColor Yellow
  
  # Check if already installed - multiple methods for reliability
  $hitokageInstalled = $false
  
  # Method 1: Check if command is available
  if (Have "hitokage") {
    Write-Host "✅ Hitokage command found. Already installed." -ForegroundColor Green
    $hitokageInstalled = $true
  }
  
  # Method 2: Check registry (both 32-bit and 64-bit locations)
  if (-not $hitokageInstalled) {
    $regPaths = @(
      "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
      "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($regPath in $regPaths) {
      $installed = Get-ItemProperty $regPath -ErrorAction SilentlyContinue | 
                   Where-Object { $_.DisplayName -like "*hitokage*" -or $_.DisplayName -like "*Hitokage*" }
      if ($installed) {
        Write-Host "✅ Hitokage found in installed programs. Already installed." -ForegroundColor Green
        $hitokageInstalled = $true
        break
      }
    }
  }
  
  # Method 3: Check common installation paths
  if (-not $hitokageInstalled) {
    $commonPaths = @(
      "$env:ProgramFiles\Hitokage",
      "${env:ProgramFiles(x86)}\Hitokage",
      "$env:LOCALAPPDATA\Programs\Hitokage"
    )
    foreach ($path in $commonPaths) {
      if (Test-Path $path) {
        Write-Host "✅ Hitokage installation directory found at: $path" -ForegroundColor Green
        $hitokageInstalled = $true
        break
      }
    }
  }
  
  if (-not $hitokageInstalled) {
    $msiUrl = "https://github.com/codyduong/hitokage/releases/download/nightly/hitokage-nightly-x86_64.msi"
    $tempMsi = Join-Path $env:TEMP "hitokage-nightly-x86_64.msi"
    
    try {
      Write-Host ""
      Write-Host "Downloading hitokage from: $msiUrl" -ForegroundColor Cyan
      Invoke-WebRequest -Uri $msiUrl -OutFile $tempMsi -ErrorAction Stop -UseBasicParsing
      
      if (-not (Test-Path $tempMsi)) {
        throw "Downloaded file not found at: $tempMsi"
      }
      
      Write-Host "Installing hitokage MSI..." -ForegroundColor Cyan
      Write-Host "   Note: This requires administrator privileges" -ForegroundColor Yellow
      Write-Host "   If prompted, please allow elevation" -ForegroundColor Yellow
      
      # Try to install with elevation if not already elevated
      $isElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
      
      if ($isElevated) {
        # Already elevated, install directly
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tempMsi`" /quiet /norestart" -Wait -PassThru -NoNewWindow
        $exitCode = $process.ExitCode
      } else {
        # Not elevated, try to elevate
        Write-Host "   Attempting to elevate for installation..." -ForegroundColor Yellow
        Write-Host "   A UAC prompt will appear - please approve to continue" -ForegroundColor Yellow
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tempMsi`" /quiet /norestart" -Verb RunAs -Wait -PassThru
        $exitCode = $process.ExitCode
      }
      
      # MSI exit codes: 0 = success, 3010 = success with restart required
      if ($exitCode -eq 0 -or $exitCode -eq 3010) {
        Write-Host "✅ Hitokage MSI installation completed (exit code: $exitCode)" -ForegroundColor Green
        
        # Wait a moment for installation to complete and PATH to update
        Start-Sleep -Seconds 2
        
        # Verify installation
        $verifyInstalled = $false
        if (Have "hitokage") {
          Write-Host "✅ Hitokage command is now available" -ForegroundColor Green
          $verifyInstalled = $true
        } else {
          # Check registry again
          $installed = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
                       Where-Object { $_.DisplayName -like "*hitokage*" -or $_.DisplayName -like "*Hitokage*" }
          if ($installed) {
            Write-Host "✅ Hitokage installed, but command may not be in PATH yet" -ForegroundColor Yellow
            Write-Host "   You may need to restart your terminal or add it to PATH manually" -ForegroundColor Yellow
            $verifyInstalled = $true
          }
        }
        
        if (-not $verifyInstalled) {
          Write-Host "⚠️  Installation completed but hitokage command not found" -ForegroundColor Yellow
          Write-Host "   You may need to restart your terminal or check installation manually" -ForegroundColor Yellow
        }
      } else {
        Write-Host "⚠️  Hitokage installation returned exit code: $exitCode" -ForegroundColor Yellow
        Write-Host "   Common exit codes: 1603 (fatal error), 1618 (another install in progress)" -ForegroundColor Yellow
        Write-Host "   You may need to install manually or run with elevated permissions" -ForegroundColor Yellow
        Write-Host "   Manual install: Download and run $msiUrl" -ForegroundColor Cyan
      }
      
      # Clean up
      if (Test-Path $tempMsi) {
        Remove-Item $tempMsi -Force -ErrorAction SilentlyContinue
      }
    } catch {
      Write-Host "❌ Failed to install hitokage: $($_.Exception.Message)" -ForegroundColor Red
      Write-Host "   Error details: $($_.Exception.GetType().FullName)" -ForegroundColor Red
      Write-Host "   You can install manually from: $msiUrl" -ForegroundColor Yellow
      
      # Clean up on error
      if (Test-Path $tempMsi) {
        Remove-Item $tempMsi -Force -ErrorAction SilentlyContinue
      }
    }
  }
}

Write-Host ""
Write-Host "✅ Installation complete." -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  - Apply your dotfiles: chezmoi apply"
Write-Host "  - Start komorebi: komorebic.exe start"
Write-Host "  - Start whkd: whkd"
if (-not $NoHitokage) {
  Write-Host "  - Start hitokage: hitokage"
}


