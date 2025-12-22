#!/usr/bin/env bash
# Test suite for chezmoi dotfiles setup
# Validates structure, templates, OS isolation, and run scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ERRORS=0
WARNINGS=0

log_error() {
  echo "❌ ERROR: $1" >&2
  ((ERRORS++)) || true
}

log_warning() {
  echo "⚠️  WARNING: $1" >&2
  ((WARNINGS++)) || true
}

log_success() {
  echo "✅ $1"
}

test_file_exists() {
  if [[ ! -f "$1" ]]; then
    log_error "Missing required file: $1"
    return 1
  fi
  log_success "Found: $1"
  return 0
}

test_dir_exists() {
  if [[ ! -d "$1" ]]; then
    log_error "Missing required directory: $1"
    return 1
  fi
  log_success "Found directory: $1"
  return 0
}

test_template_contains() {
  local file="$1"
  local pattern="$2"
  local description="${3:-pattern}"
  
  if ! grep -q "$pattern" "$file" 2>/dev/null; then
    log_error "$file does not contain $description: $pattern"
    return 1
  fi
  log_success "$file contains $description"
  return 0
}

test_os_condition() {
  local file="$1"
  local os="$2"
  local expected_condition="$3"
  
  if ! grep -q "$expected_condition" "$file" 2>/dev/null; then
    log_error "$file missing OS condition for $os: expected '$expected_condition'"
    return 1
  fi
  log_success "$file has correct OS condition for $os"
  return 0
}

echo "🧪 Testing Chezmoi Dotfiles Setup"
echo "=================================="
echo ""

# Test 1: Required directory structure
echo "📁 Testing directory structure..."
test_dir_exists "dot_config"
test_dir_exists "dot_config/alacritty"
test_dir_exists "dot_config/btop"
test_dir_exists "dot_config/nvim"
test_dir_exists "dot_config/zellij"
test_dir_exists "dot_wezterm"
test_dir_exists "dot_wezterm/layouts"
test_dir_exists "dot_wezterm/lib"
test_dir_exists "themes"
echo ""

# Test 2: Required config templates
echo "📄 Testing required config templates..."
test_file_exists "dot_config/.theme-trigger.tmpl"
test_file_exists "dot_config/starship.toml.tmpl"
test_file_exists "dot_config/fastfetch/config.jsonc.tmpl"
test_file_exists "dot_config/gh/config.yml.tmpl"
test_file_exists "dot_config/gh/hosts.yml.tmpl"
test_file_exists "dot_config/lazygit/config.yml.tmpl"
test_file_exists "dot_config/lazydocker/config.yml.tmpl"
test_file_exists "dot_config/neofetch/config.conf.tmpl"
test_file_exists "dot_config/bleachbit/bleachbit.ini.tmpl"
test_file_exists "dot_wezterm.lua.tmpl"
echo ""

# Test 3: Theme trigger file
echo "🎨 Testing theme trigger mechanism..."
if test_file_exists "dot_config/.theme-trigger.tmpl"; then
  test_template_contains "dot_config/.theme-trigger.tmpl" "current_theme" "theme variable"
fi
echo ""

# Test 4: Run scripts exist and are properly named
echo "🔧 Testing run scripts..."
test_file_exists "run_dot_config/.theme-trigger_apply-lxpanel-theme.sh.tmpl"
test_file_exists "run_dot_config/.theme-trigger_apply-wayfire-theme.sh.tmpl"
test_file_exists "run_dot_config/.theme-trigger_apply-windows-theme.ps1.tmpl"

# Check for old incorrectly named scripts
if [[ -f "run_onchange_apply-lxpanel-theme.sh.tmpl" ]] || [[ -f "run_onchange_apply-wayfire-theme.sh.tmpl" ]]; then
  log_error "Found old run_onchange scripts - these should be renamed to run_dot_config/.theme-trigger_apply-*.sh.tmpl"
fi
echo ""

# Test 5: OS-specific isolation
echo "🖥️  Testing OS-specific isolation..."

# Windows-only configs
echo "  Windows-only configs:"
test_os_condition "dot_config/komorebi/komorebi.json.tmpl" "windows" '{{- if eq .chezmoi.os "windows" }}'
test_os_condition "dot_config/whkdrc.tmpl" "windows" '{{- if eq .chezmoi.os "windows" }}'
test_os_condition "dot_config/hitokage/init.lua.tmpl" "windows" '{{- if eq .chezmoi.os "windows" }}'
test_os_condition "run_dot_config/.theme-trigger_apply-windows-theme.ps1.tmpl" "windows" '{{- if eq .chezmoi.os "windows" }}'

# Linux-only configs
echo "  Linux-only configs:"
test_os_condition "dot_config/lxpanel/default/panel.tmpl" "linux" '{{- if eq .chezmoi.os "linux" }}'
test_os_condition "dot_config/wayfire.ini.tmpl" "linux" '{{- if eq .chezmoi.os "linux" }}'
test_os_condition "dot_config/zellij/config.kdl.tmpl" "linux" '{{- if eq .chezmoi.os "linux" }}'
test_os_condition "dot_config/ghostty/config.tmpl" "linux" '{{- if eq .chezmoi.os "linux" }}'
test_os_condition "dot_config/neofetch/config.conf.tmpl" "linux" '{{- if eq .chezmoi.os "linux" }}'
test_os_condition "run_dot_config/.theme-trigger_apply-lxpanel-theme.sh.tmpl" "linux" '{{- if eq .chezmoi.os "linux" }}'
test_os_condition "run_dot_config/.theme-trigger_apply-wayfire-theme.sh.tmpl" "linux" '{{- if eq .chezmoi.os "linux" }}'

# Cross-platform configs
echo "  Cross-platform configs:"
test_template_contains "dot_wezterm.lua.tmpl" '{{- if or (eq .chezmoi.os "windows") (eq .chezmoi.os "linux") }}' "cross-platform condition"
test_template_contains "dot_config/starship.toml.tmpl" "current_theme" "theme variable"
test_template_contains "dot_config/fastfetch/config.jsonc.tmpl" "current_theme" "theme variable"
echo ""

# Test 6: Run scripts use proper path detection
echo "📍 Testing path detection in run scripts..."
if test_file_exists "run_dot_config/.theme-trigger_apply-lxpanel-theme.sh.tmpl"; then
  if ! grep -q "CHEZMOI_DATA_DIR" "run_dot_config/.theme-trigger_apply-lxpanel-theme.sh.tmpl" 2>/dev/null; then
    log_error "Linux run script missing CHEZMOI_DATA_DIR detection"
  else
    log_success "Linux run script has proper path detection"
  fi
  
  if grep -q "\${HOME}/.local/share/chezmoi/.chezmoidata.yaml" "run_dot_config/.theme-trigger_apply-lxpanel-theme.sh.tmpl" 2>/dev/null; then
    log_warning "Linux run script may have hardcoded path (should use variable detection)"
  fi
fi

if test_file_exists "run_dot_config/.theme-trigger_apply-windows-theme.ps1.tmpl"; then
  if ! grep -q "CHEZMOI_DATA_DIR" "run_dot_config/.theme-trigger_apply-windows-theme.ps1.tmpl" 2>/dev/null; then
    log_error "Windows run script missing CHEZMOI_DATA_DIR detection"
  else
    log_success "Windows run script has proper path detection"
  fi
  
  if grep -q "LOCALAPPDATA.*chezmoi" "run_dot_config/.theme-trigger_apply-windows-theme.ps1.tmpl" 2>/dev/null; then
    log_success "Windows run script uses LOCALAPPDATA"
  fi
fi
echo ""

# Test 7: WezTerm config supports both platforms
echo "🪟 Testing WezTerm cross-platform support..."
if test_file_exists "dot_wezterm.lua.tmpl"; then
  if grep -q '{{- if eq .chezmoi.os "windows" }}' "dot_wezterm.lua.tmpl" 2>/dev/null && \
     ! grep -q '{{- if or' "dot_wezterm.lua.tmpl" 2>/dev/null; then
    log_error "WezTerm config only supports Windows - should support Linux too"
  else
    log_success "WezTerm config supports both Windows and Linux"
  fi
  
  # Check for platform-specific theme path detection
  if grep -q "LOCALAPPDATA" "dot_wezterm.lua.tmpl" 2>/dev/null && \
     grep -q "XDG_DATA_HOME\|HOME.*.local/share" "dot_wezterm.lua.tmpl" 2>/dev/null; then
    log_success "WezTerm config has platform-specific theme path detection"
  else
    log_warning "WezTerm config may not have proper cross-platform theme path detection"
  fi
fi
echo ""

# Test 8: Theme files exist for all themes
echo "🎨 Testing theme completeness..."
THEMES=("catppuccin" "everforest" "gruvbox" "kanagawa" "matte-black" "nord" "osaka-jade" "ristretto" "rose-pine" "tokyo-night")

for theme in "${THEMES[@]}"; do
  if [[ ! -d "themes/$theme" ]]; then
    log_error "Missing theme directory: themes/$theme"
    continue
  fi
  
  test_file_exists "themes/$theme/wezterm.lua"
  test_file_exists "themes/$theme/alacritty.toml"
  test_file_exists "themes/$theme/zellij.kdl"
  test_file_exists "themes/$theme/neovim.lua"
  test_file_exists "themes/$theme/btop.theme"
done
echo ""

# Test 9: Template syntax validation (basic)
echo "🔍 Testing template syntax..."
TEMPLATE_FILES=$(find dot_config dot_wezterm.lua.tmpl run_dot_config -name "*.tmpl" -type f 2>/dev/null || true)

for file in $TEMPLATE_FILES; do
  if [[ ! -f "$file" ]]; then
    continue
  fi
  
  # Check for unclosed template tags (basic check)
  open_tags=$(grep -o '{{' "$file" 2>/dev/null | wc -l || echo "0")
  close_tags=$(grep -o '}}' "$file" 2>/dev/null | wc -l || echo "0")
  
  if [[ "$open_tags" != "$close_tags" ]]; then
    log_warning "Possible unclosed template tags in $file ({{ count: $open_tags, }} count: $close_tags)"
  fi
done
echo ""

# Test 10: Check for common issues
echo "🔎 Checking for common issues..."

# Check if waffle still calls chezmoi apply
if [[ -f "../waffle/cmd/theme.go" ]]; then
  if grep -q 'exec.Command("chezmoi", "apply")' "../waffle/cmd/theme.go" 2>/dev/null; then
    log_error "waffle/cmd/theme.go still calls chezmoi apply - should be removed"
  else
    log_success "waffle/cmd/theme.go does not call chezmoi apply"
  fi
  
  if grep -q 'exec.Command("chezmoi", "apply")' "../waffle/cmd/font.go" 2>/dev/null; then
    log_error "waffle/cmd/font.go still calls chezmoi apply - should be removed"
  else
    log_success "waffle/cmd/font.go does not call chezmoi apply"
  fi
fi

# Check for hardcoded usernames
if grep -r "Jeff-Barlow-Spady\|jeff-barlow-spady" dot_config themes 2>/dev/null | grep -v ".git" | grep -v "test.sh" | head -1 | grep -q .; then
  log_warning "Found hardcoded username - should use template variables"
fi
echo ""

# Summary
echo "=================================="
echo "📊 Test Summary"
echo "=================================="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [[ $ERRORS -eq 0 ]]; then
  echo ""
  echo "✅ All critical tests passed!"
  exit 0
else
  echo ""
  echo "❌ Some tests failed. Please fix the errors above."
  exit 1
fi

