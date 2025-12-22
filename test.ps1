# PowerShell test suite for chezmoi dotfiles setup
# Validates structure, templates, OS isolation, and run scripts on Windows

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$Errors = 0
$Warnings = 0

function Log-Error {
    param([string]$Message)
    Write-Host "❌ ERROR: $Message" -ForegroundColor Red
    $script:Errors++
}

function Log-Warning {
    param([string]$Message)
    Write-Host "⚠️  WARNING: $Message" -ForegroundColor Yellow
    $script:Warnings++
}

function Log-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Test-FileExists {
    param([string]$Path, [string]$Description = $Path)
    
    if (-not (Test-Path $Path -PathType Leaf)) {
        Log-Error "Missing required file: $Path"
        return $false
    }
    Log-Success "Found: $Path"
    return $true
}

function Test-DirectoryExists {
    param([string]$Path, [string]$Description = $Path)
    
    if (-not (Test-Path $Path -PathType Container)) {
        Log-Error "Missing required directory: $Path"
        return $false
    }
    Log-Success "Found directory: $Path"
    return $true
}

function Test-TemplateContains {
    param([string]$File, [string]$Pattern, [string]$Description = "pattern")
    
    if (-not (Test-Path $File)) {
        return $false
    }
    
    $content = Get-Content $File -Raw -ErrorAction SilentlyContinue
    if ($content -notmatch [regex]::Escape($Pattern)) {
        Log-Error "$File does not contain $Description : $Pattern"
        return $false
    }
    Log-Success "$File contains $Description"
    return $true
}

function Test-OSCondition {
    param([string]$File, [string]$OS, [string]$ExpectedCondition)
    
    if (-not (Test-Path $File)) {
        return $false
    }
    
    $content = Get-Content $File -Raw -ErrorAction SilentlyContinue
    if ($content -notmatch [regex]::Escape($ExpectedCondition)) {
        Log-Error "$File missing OS condition for $OS : expected '$ExpectedCondition'"
        return $false
    }
    Log-Success "$File has correct OS condition for $OS"
    return $true
}

Write-Host "🧪 Testing Chezmoi Dotfiles Setup (Windows)" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Required directory structure
Write-Host "📁 Testing directory structure..." -ForegroundColor Yellow
Test-DirectoryExists "dot_config"
Test-DirectoryExists "dot_config\alacritty"
Test-DirectoryExists "dot_config\btop"
Test-DirectoryExists "dot_config\nvim"
Test-DirectoryExists "dot_config\zellij"
Test-DirectoryExists "dot_wezterm"
Test-DirectoryExists "dot_wezterm\layouts"
Test-DirectoryExists "dot_wezterm\lib"
Test-DirectoryExists "themes"
Write-Host ""

# Test 2: Required config templates
Write-Host "📄 Testing required config templates..." -ForegroundColor Yellow
Test-FileExists "dot_config\.theme-trigger.tmpl"
Test-FileExists "dot_config\starship.toml.tmpl"
Test-FileExists "dot_config\fastfetch\config.jsonc.tmpl"
Test-FileExists "dot_config\gh\config.yml.tmpl"
Test-FileExists "dot_config\gh\hosts.yml.tmpl"
Test-FileExists "dot_config\lazygit\config.yml.tmpl"
Test-FileExists "dot_config\lazydocker\config.yml.tmpl"
Test-FileExists "dot_config\bleachbit\bleachbit.ini.tmpl"
Test-FileExists "dot_wezterm.lua.tmpl"
Write-Host ""

# Test 3: Theme trigger file
Write-Host "🎨 Testing theme trigger mechanism..." -ForegroundColor Yellow
if (Test-FileExists "dot_config\.theme-trigger.tmpl") {
    Test-TemplateContains "dot_config\.theme-trigger.tmpl" "current_theme" "theme variable"
}
Write-Host ""

# Test 4: Run scripts exist and are properly named
Write-Host "🔧 Testing run scripts..." -ForegroundColor Yellow
Test-FileExists "run_dot_config\.theme-trigger_apply-windows-theme.ps1.tmpl"

# Check for old incorrectly named scripts
if (Test-Path "run_onchange_apply-lxpanel-theme.sh.tmpl") -or (Test-Path "run_onchange_apply-wayfire-theme.sh.tmpl") {
    Log-Error "Found old run_onchange scripts - these should be renamed"
}
Write-Host ""

# Test 5: OS-specific isolation
Write-Host "🖥️  Testing OS-specific isolation..." -ForegroundColor Yellow
Write-Host "  Windows-only configs:" -ForegroundColor Cyan
Test-OSCondition "dot_config\komorebi\komorebi.json.tmpl" "windows" '{{- if eq .chezmoi.os "windows" }}'
Test-OSCondition "dot_config\whkdrc.tmpl" "windows" '{{- if eq .chezmoi.os "windows" }}'
Test-OSCondition "dot_config\hitokage\init.lua.tmpl" "windows" '{{- if eq .chezmoi.os "windows" }}'
Test-OSCondition "run_dot_config\.theme-trigger_apply-windows-theme.ps1.tmpl" "windows" '{{- if eq .chezmoi.os "windows" }}'

Write-Host "  Cross-platform configs:" -ForegroundColor Cyan
Test-TemplateContains "dot_wezterm.lua.tmpl" '{{- if or (eq .chezmoi.os "windows") (eq .chezmoi.os "linux") }}' "cross-platform condition"
Test-TemplateContains "dot_config\starship.toml.tmpl" "current_theme" "theme variable"
Test-TemplateContains "dot_config\fastfetch\config.jsonc.tmpl" "current_theme" "theme variable"
Write-Host ""

# Test 6: Run scripts use proper path detection
Write-Host "📍 Testing path detection in run scripts..." -ForegroundColor Yellow
if (Test-FileExists "run_dot_config\.theme-trigger_apply-windows-theme.ps1.tmpl") {
    $content = Get-Content "run_dot_config\.theme-trigger_apply-windows-theme.ps1.tmpl" -Raw
    if ($content -notmatch "CHEZMOI_DATA_DIR") {
        Log-Error "Windows run script missing CHEZMOI_DATA_DIR detection"
    } else {
        Log-Success "Windows run script has proper path detection"
    }
    
    if ($content -match "LOCALAPPDATA.*chezmoi") {
        Log-Success "Windows run script uses LOCALAPPDATA"
    }
}
Write-Host ""

# Test 7: WezTerm config supports both platforms
Write-Host "🪟 Testing WezTerm cross-platform support..." -ForegroundColor Yellow
if (Test-FileExists "dot_wezterm.lua.tmpl") {
    $content = Get-Content "dot_wezterm.lua.tmpl" -Raw
    if ($content -match '{{- if eq .chezmoi.os "windows" }}' -and $content -notmatch '{{- if or') {
        Log-Error "WezTerm config only supports Windows - should support Linux too"
    } else {
        Log-Success "WezTerm config supports both Windows and Linux"
    }
    
    if ($content -match "LOCALAPPDATA" -and ($content -match "XDG_DATA_HOME" -or $content -match "HOME.*\.local/share")) {
        Log-Success "WezTerm config has platform-specific theme path detection"
    } else {
        Log-Warning "WezTerm config may not have proper cross-platform theme path detection"
    }
}
Write-Host ""

# Test 8: Theme files exist for all themes
Write-Host "🎨 Testing theme completeness..." -ForegroundColor Yellow
$Themes = @("catppuccin", "everforest", "gruvbox", "kanagawa", "matte-black", "nord", "osaka-jade", "ristretto", "rose-pine", "tokyo-night")

foreach ($theme in $Themes) {
    $themeDir = "themes\$theme"
    if (-not (Test-Path $themeDir -PathType Container)) {
        Log-Error "Missing theme directory: $themeDir"
        continue
    }
    
    Test-FileExists "$themeDir\wezterm.lua"
    Test-FileExists "$themeDir\alacritty.toml"
    Test-FileExists "$themeDir\zellij.kdl"
    Test-FileExists "$themeDir\neovim.lua"
    Test-FileExists "$themeDir\btop.theme"
}
Write-Host ""

# Test 9: Check for common issues
Write-Host "🔎 Checking for common issues..." -ForegroundColor Yellow

# Check if waffle still calls chezmoi apply
$waffleThemePath = "..\waffle\cmd\theme.go"
$waffleFontPath = "..\waffle\cmd\font.go"

if (Test-Path $waffleThemePath) {
    $content = Get-Content $waffleThemePath -Raw
    if ($content -match 'exec\.Command\("chezmoi", "apply"\)') {
        Log-Error "waffle/cmd/theme.go still calls chezmoi apply - should be removed"
    } else {
        Log-Success "waffle/cmd/theme.go does not call chezmoi apply"
    }
}

if (Test-Path $waffleFontPath) {
    $content = Get-Content $waffleFontPath -Raw
    if ($content -match 'exec\.Command\("chezmoi", "apply"\)') {
        Log-Error "waffle/cmd/font.go still calls chezmoi apply - should be removed"
    } else {
        Log-Success "waffle/cmd/font.go does not call chezmoi apply"
    }
}

# Check for hardcoded usernames
$hardcoded = Get-ChildItem -Path dot_config,themes -Recurse -File -ErrorAction SilentlyContinue | 
    Select-String -Pattern "Jeff-Barlow-Spady|jeff-barlow-spady" | 
    Where-Object { $_.Path -notmatch "test\.ps1|test\.sh" }
if ($hardcoded) {
    Log-Warning "Found hardcoded username - should use template variables"
}
Write-Host ""

# Summary
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "📊 Test Summary" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Errors: $Errors" -ForegroundColor $(if ($Errors -eq 0) { "Green" } else { "Red" })
Write-Host "Warnings: $Warnings" -ForegroundColor $(if ($Warnings -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($Errors -eq 0) {
    Write-Host "✅ All critical tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Some tests failed. Please fix the errors above." -ForegroundColor Red
    exit 1
}

