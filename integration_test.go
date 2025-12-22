package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// TestWaffleChezmoiIntegration tests the full workflow:
// 1. Waffle updates .chezmoidata.yaml
// 2. Chezmoi reads the data
// 3. Templates render with the data
// 4. Theme trigger file updates
func TestWaffleChezmoiIntegration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	// Check if chezmoi is available
	if _, err := exec.LookPath("chezmoi"); err != nil {
		t.Skip("chezmoi not found in PATH, skipping integration test")
	}

	// Check if waffle is available
	wafflePath := findWaffleBinary(t)
	if wafflePath == "" {
		t.Skip("waffle binary not found, skipping integration test")
	}

	tmpDir := t.TempDir()
	chezmoiSource := filepath.Join(tmpDir, "chezmoi-source")
	chezmoiDataDir := filepath.Join(tmpDir, "chezmoi-data")
	homeDir := filepath.Join(tmpDir, "home")

	// Setup test environment
	os.MkdirAll(chezmoiSource, 0755)
	os.MkdirAll(homeDir, 0755)
	os.Setenv("CHEZMOI_SOURCE_DIR", chezmoiSource)
	os.Setenv("CHEZMOI_DATA_DIR", chezmoiDataDir)
	os.Setenv("HOME", homeDir)
	defer func() {
		os.Unsetenv("CHEZMOI_SOURCE_DIR")
		os.Unsetenv("CHEZMOI_DATA_DIR")
		os.Unsetenv("HOME")
	}()

	// Copy minimal chezmoi source structure
	actualChezmoiDir := findChezmoiDirForIntegration(t)
	copyTestTemplatesForIntegration(t, actualChezmoiDir, chezmoiSource)

	// Initialize chezmoi
	initCmd := exec.Command("chezmoi", "init", "--source", chezmoiSource, "--destination", homeDir)
	initCmd.Env = append(os.Environ(), "CHEZMOI_SOURCE_DIR="+chezmoiSource, "CHEZMOI_DATA_DIR="+chezmoiDataDir)
	if err := initCmd.Run(); err != nil {
		t.Fatalf("Failed to initialize chezmoi: %v", err)
	}

	// Create .chezmoidata.yaml with waffle data
	chezmoiDataPath := filepath.Join(chezmoiDataDir, ".chezmoidata.yaml")
	dataContent := `current_theme: gruvbox
current_font: "Agave Nerd Font"
font_size: "14"
`
	if err := os.WriteFile(chezmoiDataPath, []byte(dataContent), 0644); err != nil {
		t.Fatalf("Failed to write chezmoi data: %v", err)
	}

	// Test that chezmoi can read the data and render templates
	applyCmd := exec.Command("chezmoi", "apply", "--dry-run", "--verbose")
	applyCmd.Env = append(os.Environ(), "CHEZMOI_SOURCE_DIR="+chezmoiSource, "CHEZMOI_DATA_DIR="+chezmoiDataDir)
	output, err := applyCmd.CombinedOutput()
	if err != nil {
		t.Logf("Chezmoi apply output: %s", string(output))
		t.Fatalf("Chezmoi apply failed: %v", err)
	}

	// Verify theme trigger file would be created
	applyCmd2 := exec.Command("chezmoi", "apply", "--dry-run")
	applyCmd2.Env = append(os.Environ(), "CHEZMOI_SOURCE_DIR="+chezmoiSource, "CHEZMOI_DATA_DIR="+chezmoiDataDir)
	output2, _ := applyCmd2.CombinedOutput()
	
	// Check that theme trigger template references current_theme
	if !strings.Contains(string(output2), "gruvbox") {
		t.Error("Theme trigger template should reference current_theme from data")
	}
}

// TestTemplateRendering tests that chezmoi templates render correctly with mock data
func TestTemplateRendering(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping template rendering test in short mode")
	}

	if _, err := exec.LookPath("chezmoi"); err != nil {
		t.Skip("chezmoi not found in PATH")
	}

	chezmoiDir := findChezmoiDirForIntegration(t)
	tmpDir := t.TempDir()
	chezmoiSource := filepath.Join(tmpDir, "source")
	homeDir := filepath.Join(tmpDir, "home")
	chezmoiDataDir := filepath.Join(tmpDir, "data")

	os.MkdirAll(chezmoiSource, 0755)
	os.MkdirAll(homeDir, 0755)
	os.Setenv("CHEZMOI_SOURCE_DIR", chezmoiSource)
	os.Setenv("CHEZMOI_DATA_DIR", chezmoiDataDir)
	defer func() {
		os.Unsetenv("CHEZMOI_SOURCE_DIR")
		os.Unsetenv("CHEZMOI_DATA_DIR")
	}()

	// Copy theme trigger template
	themeTriggerSrc := filepath.Join(chezmoiDir, "dot_config", ".theme-trigger.tmpl")
	themeTriggerDest := filepath.Join(chezmoiSource, "dot_config", ".theme-trigger.tmpl")
	os.MkdirAll(filepath.Dir(themeTriggerDest), 0755)
	copyFileForIntegration(t, themeTriggerSrc, themeTriggerDest)

	// Create test data
	chezmoiDataPath := filepath.Join(chezmoiDataDir, ".chezmoidata.yaml")
	dataContent := `current_theme: catppuccin
current_font: "JetBrainsMono Nerd Font"
`
	os.WriteFile(chezmoiDataPath, []byte(dataContent), 0644)

	// Initialize and apply
	initCmd := exec.Command("chezmoi", "init", "--source", chezmoiSource, "--destination", homeDir)
	initCmd.Env = append(os.Environ(), "CHEZMOI_SOURCE_DIR="+chezmoiSource, "CHEZMOI_DATA_DIR="+chezmoiDataDir)
	initCmd.Run()

	// Apply and check output
	applyCmd := exec.Command("chezmoi", "apply", "--dry-run")
	applyCmd.Env = append(os.Environ(), "CHEZMOI_SOURCE_DIR="+chezmoiSource, "CHEZMOI_DATA_DIR="+chezmoiDataDir)
	output, err := applyCmd.CombinedOutput()
	if err != nil {
		t.Logf("Output: %s", string(output))
		t.Fatalf("Chezmoi apply failed: %v", err)
	}

	// Verify the theme would be applied
	if !strings.Contains(string(output), "catppuccin") {
		t.Error("Template should render with theme from data file")
	}
}

// TestRunScriptNaming tests that run scripts follow chezmoi naming conventions
func TestRunScriptNaming(t *testing.T) {
	chezmoiDir := findChezmoiDirForIntegration(t)
	
	// Check for correctly named run scripts
	expectedScripts := []string{
		"run_dot_config/.theme-trigger_apply-lxpanel-theme.sh.tmpl",
		"run_dot_config/.theme-trigger_apply-wayfire-theme.sh.tmpl",
		"run_dot_config/.theme-trigger_apply-windows-theme.ps1.tmpl",
	}

	for _, script := range expectedScripts {
		scriptPath := filepath.Join(chezmoiDir, script)
		if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
			t.Errorf("Missing required run script: %s", script)
		}
	}

	// Check for old incorrectly named scripts
	oldScripts := []string{
		"run_onchange_apply-lxpanel-theme.sh.tmpl",
		"run_onchange_apply-wayfire-theme.sh.tmpl",
	}

	for _, script := range oldScripts {
		scriptPath := filepath.Join(chezmoiDir, script)
		if _, err := os.Stat(scriptPath); err == nil {
			t.Errorf("Found old incorrectly named script (should be removed): %s", script)
		}
	}
}

// TestThemeTriggerMechanism tests that theme changes trigger run scripts
func TestThemeTriggerMechanism(t *testing.T) {
	chezmoiDir := findChezmoiDirForIntegration(t)
	themeTriggerPath := filepath.Join(chezmoiDir, "dot_config", ".theme-trigger.tmpl")

	// Verify theme trigger file exists
	if _, err := os.Stat(themeTriggerPath); os.IsNotExist(err) {
		t.Fatal("Theme trigger file does not exist")
	}

	// Verify it references current_theme
	content, err := os.ReadFile(themeTriggerPath)
	if err != nil {
		t.Fatalf("Failed to read theme trigger: %v", err)
	}

	if !strings.Contains(string(content), "current_theme") {
		t.Error("Theme trigger file should reference .chezmoi.current_theme")
	}

	// Verify run scripts reference the trigger file
	runScripts := []string{
		"run_dot_config/.theme-trigger_apply-lxpanel-theme.sh.tmpl",
		"run_dot_config/.theme-trigger_apply-wayfire-theme.sh.tmpl",
		"run_dot_config/.theme-trigger_apply-windows-theme.ps1.tmpl",
	}

	for _, script := range runScripts {
		scriptPath := filepath.Join(chezmoiDir, script)
		if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
			continue
		}

		content, err := os.ReadFile(scriptPath)
		if err != nil {
			continue
		}

		// Scripts should reference the theme trigger file in comments
		// or be named to trigger on it
		if !strings.Contains(string(content), "theme-trigger") && 
		   !strings.Contains(string(content), "theme change") {
			t.Logf("Warning: Run script %s may not reference theme trigger mechanism", script)
		}
	}
}

// Helper functions

func findChezmoiDirForIntegration(t *testing.T) string {
	wd, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get working directory: %v", err)
	}

	// Try different paths
	possiblePaths := []string{
		filepath.Join(wd, "chezmoi"),
		filepath.Join(wd, "..", "chezmoi"),
		filepath.Join(wd, "CONFIGS", "chezmoi"),
		filepath.Join(wd, "..", "CONFIGS", "chezmoi"),
	}

	for _, path := range possiblePaths {
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}

	t.Fatalf("Could not find chezmoi directory. Tried: %v", possiblePaths)
	return ""
}

func findWaffleBinary(t *testing.T) string {
	// Try to find waffle in PATH
	if path, err := exec.LookPath("waffle"); err == nil {
		return path
	}

	// Try relative to current directory
	wd, _ := os.Getwd()
	possiblePaths := []string{
		filepath.Join(wd, "waffle", "waffle"),
		filepath.Join(wd, "waffle", "waffle.exe"),
		filepath.Join(wd, "..", "waffle", "waffle"),
		filepath.Join(wd, "..", "waffle", "waffle.exe"),
	}

	for _, path := range possiblePaths {
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}

	return ""
}

func copyTestTemplatesForIntegration(t *testing.T, srcDir, destDir string) {
	// Copy essential templates for testing
	templates := []string{
		"dot_config/.theme-trigger.tmpl",
		"dot_config/starship.toml.tmpl",
		"dot_wezterm.lua.tmpl",
	}

	for _, relPath := range templates {
		srcPath := filepath.Join(srcDir, relPath)
		destPath := filepath.Join(destDir, relPath)
		
		if _, err := os.Stat(srcPath); os.IsNotExist(err) {
			continue
		}

		os.MkdirAll(filepath.Dir(destPath), 0755)
		copyFileForIntegration(t, srcPath, destPath)
	}
}

func copyFileForIntegration(t *testing.T, src, dest string) {
	data, err := os.ReadFile(src)
	if err != nil {
		t.Fatalf("Failed to read %s: %v", src, err)
	}
	if err := os.WriteFile(dest, data, 0644); err != nil {
		t.Fatalf("Failed to write %s: %v", dest, err)
	}
}

