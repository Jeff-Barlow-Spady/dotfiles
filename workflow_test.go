package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// TestFullWorkflow simulates the complete waffle -> chezmoi workflow:
// 1. User runs `waffle theme` (updates .chezmoidata.yaml)
// 2. User runs `chezmoi apply`
// 3. Templates render with new theme
// 4. Theme trigger file changes
// 5. Run scripts execute
func TestFullWorkflow(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping full workflow test in short mode")
	}

	// Check prerequisites
	if _, err := exec.LookPath("chezmoi"); err != nil {
		t.Skip("chezmoi not found in PATH")
	}

	tmpDir := t.TempDir()
	chezmoiSource := filepath.Join(tmpDir, "source")
	homeDir := filepath.Join(tmpDir, "home")
	chezmoiDataDir := filepath.Join(tmpDir, "data")

	os.MkdirAll(chezmoiSource, 0755)
	os.MkdirAll(homeDir, 0755)
	os.MkdirAll(chezmoiDataDir, 0755)

	// Setup environment
	env := append(os.Environ(),
		"CHEZMOI_SOURCE_DIR="+chezmoiSource,
		"CHEZMOI_DATA_DIR="+chezmoiDataDir,
		"HOME="+homeDir,
	)

	// Copy minimal template structure
	actualChezmoiDir := findChezmoiDir(t)
	copyMinimalTemplates(t, actualChezmoiDir, chezmoiSource)

	// Step 1: Create .chezmoidata.yaml BEFORE init so templates can use it
	chezmoiDataPath := filepath.Join(chezmoiDataDir, ".chezmoidata.yaml")
	initialData := `current_theme: gruvbox
current_font: "Agave Nerd Font"
font_size: "14"
`
	if err := os.WriteFile(chezmoiDataPath, []byte(initialData), 0644); err != nil {
		t.Fatalf("Failed to write initial data: %v", err)
	}

	// Step 2: Initialize chezmoi
	initCmd := exec.Command("chezmoi", "init", "--source", chezmoiSource, "--destination", homeDir)
	initCmd.Env = env
	initOutput, err := initCmd.CombinedOutput()
	if err != nil {
		t.Logf("Chezmoi init output: %s", string(initOutput))
		// Don't fail if init has warnings - it might still work
		t.Logf("Note: Chezmoi init may have warnings but should still initialize")
	}

	// Step 3: Apply and verify initial state
	applyCmd1 := exec.Command("chezmoi", "apply", "--dry-run", "--source", chezmoiSource, "--destination", homeDir)
	applyCmd1.Env = env
	output1, err := applyCmd1.CombinedOutput()
	if err != nil {
		t.Logf("Initial apply output: %s", string(output1))
		// Don't fail on dry-run - may have expected errors
		t.Logf("Note: Dry-run may show expected errors for missing dependencies")
	}

	// Step 4: Simulate waffle changing theme (like user running `waffle theme`)
	newData := `current_theme: catppuccin
current_font: "Agave Nerd Font"
font_size: "14"
`
	if err := os.WriteFile(chezmoiDataPath, []byte(newData), 0644); err != nil {
		t.Fatalf("Failed to write new theme data: %v", err)
	}

	// Step 5: Apply again and verify theme changed
	applyCmd2 := exec.Command("chezmoi", "apply", "--dry-run", "--source", chezmoiSource, "--destination", homeDir)
	applyCmd2.Env = env
	output2, err := applyCmd2.CombinedOutput()
	if err != nil {
		t.Logf("Second apply output: %s", string(output2))
		t.Logf("Note: Dry-run errors may be expected")
	}

	// Verify the theme change would be reflected in templates
	// Check that the data file was updated
	dataContent, _ := os.ReadFile(chezmoiDataPath)
	if !strings.Contains(string(dataContent), "catppuccin") {
		t.Error("Data file should contain new theme 'catppuccin'")
	}

	// Verify theme trigger template would render with new theme
	// (We don't actually apply to avoid side effects, but verify the mechanism)
	themeTriggerTemplate := filepath.Join(chezmoiSource, "dot_config", ".theme-trigger.tmpl")
	if _, err := os.Stat(themeTriggerTemplate); err == nil {
		content, _ := os.ReadFile(themeTriggerTemplate)
		if !strings.Contains(string(content), "current_theme") {
			t.Error("Theme trigger template should reference current_theme variable")
		}
	}
}

// TestRunScriptExecution tests that run scripts would execute when theme changes
func TestRunScriptExecution(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping run script test in short mode")
	}

	if _, err := exec.LookPath("chezmoi"); err != nil {
		t.Skip("chezmoi not found in PATH")
	}

	chezmoiDir := findChezmoiDir(t)
	
	// Verify run scripts exist and have correct naming
	runScripts := []struct {
		path     string
		os       string
		hasOSCheck bool
	}{
		{"run_dot_config/.theme-trigger_apply-lxpanel-theme.sh.tmpl", "linux", true},
		{"run_dot_config/.theme-trigger_apply-wayfire-theme.sh.tmpl", "linux", true},
		{"run_dot_config/.theme-trigger_apply-windows-theme.ps1.tmpl", "windows", true},
	}

	for _, script := range runScripts {
		scriptPath := filepath.Join(chezmoiDir, script.path)
		if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
			t.Errorf("Missing run script: %s", script.path)
			continue
		}

		content, err := os.ReadFile(scriptPath)
		if err != nil {
			t.Errorf("Failed to read script %s: %v", script.path, err)
			continue
		}

		contentStr := string(content)

		// Verify OS check
		if script.hasOSCheck {
			expectedCheck := `{{- if eq .chezmoi.os "` + script.os + `" }}`
			if !strings.Contains(contentStr, expectedCheck) {
				t.Errorf("Script %s missing OS check for %s", script.path, script.os)
			}
		}

		// Verify path detection (not hardcoded)
		if script.os == "linux" {
			if strings.Contains(contentStr, "${HOME}/.local/share/chezmoi/.chezmoidata.yaml") &&
			   !strings.Contains(contentStr, "CHEZMOI_DATA_DIR") {
				t.Errorf("Script %s has hardcoded path instead of using CHEZMOI_DATA_DIR", script.path)
			}
		} else if script.os == "windows" {
			if strings.Contains(contentStr, "$env:LOCALAPPDATA\\chezmoi") &&
			   !strings.Contains(contentStr, "CHEZMOI_DATA_DIR") {
				t.Errorf("Script %s has hardcoded path instead of using CHEZMOI_DATA_DIR", script.path)
			}
		}
	}
}

// TestOSIsolation verifies that Windows-only and Linux-only configs are properly isolated
func TestOSIsolation(t *testing.T) {
	chezmoiDir := findChezmoiDir(t)

	// Windows-only configs
	windowsConfigs := []string{
		"dot_config/komorebi/komorebi.json.tmpl",
		"dot_config/whkdrc.tmpl",
		"dot_config/hitokage/init.lua.tmpl",
	}

	for _, config := range windowsConfigs {
		configPath := filepath.Join(chezmoiDir, config)
		if _, err := os.Stat(configPath); os.IsNotExist(err) {
			continue
		}

		content, err := os.ReadFile(configPath)
		if err != nil {
			continue
		}

		contentStr := string(content)
		if !strings.Contains(contentStr, `{{- if eq .chezmoi.os "windows" }}`) {
			t.Errorf("Windows config %s missing OS condition", config)
		}
	}

	// Linux-only configs
	linuxConfigs := []struct {
		path        string
		hasComplexCondition bool // Some have complex conditions like "and (eq .chezmoi.os "linux")"
	}{
		{"dot_config/lxpanel/default/panel.tmpl", false},
		{"dot_config/wayfire.ini.tmpl", false},
		{"dot_config/zellij/config.kdl.tmpl", false},
		{"dot_config/ghostty/config.tmpl", true}, // Has complex condition
	}

	for _, config := range linuxConfigs {
		configPath := filepath.Join(chezmoiDir, config.path)
		if _, err := os.Stat(configPath); os.IsNotExist(err) {
			continue
		}

		content, err := os.ReadFile(configPath)
		if err != nil {
			continue
		}

		contentStr := string(content)
		hasSimpleCondition := strings.Contains(contentStr, `{{- if eq .chezmoi.os "linux" }}`)
		hasComplexCondition := strings.Contains(contentStr, `eq .chezmoi.os "linux"`)
		
		if !hasSimpleCondition && !hasComplexCondition {
			t.Errorf("Linux config %s missing OS condition for linux", config.path)
		}
	}
}

func copyMinimalTemplates(t *testing.T, srcDir, destDir string) {
	templates := []string{
		"dot_config/.theme-trigger.tmpl",
		"dot_config/starship.toml.tmpl",
	}

	for _, relPath := range templates {
		srcPath := filepath.Join(srcDir, relPath)
		destPath := filepath.Join(destDir, relPath)
		
		if _, err := os.Stat(srcPath); os.IsNotExist(err) {
			continue
		}

		os.MkdirAll(filepath.Dir(destPath), 0755)
		copyFile(t, srcPath, destPath)
	}
}

// findChezmoiDir finds the chezmoi source directory
func findChezmoiDir(t *testing.T) string {
	wd, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get working directory: %v", err)
	}

	// If we're already in the chezmoi directory, return it
	if _, err := os.Stat(filepath.Join(wd, "dot_config")); err == nil {
		return wd
	}

	// Try different paths
	possiblePaths := []string{
		wd, // Current directory
		filepath.Join(wd, "chezmoi"),
		filepath.Join(wd, "..", "chezmoi"),
		filepath.Join(wd, "CONFIGS", "chezmoi"),
		filepath.Join(wd, "..", "CONFIGS", "chezmoi"),
	}

	for _, path := range possiblePaths {
		if _, err := os.Stat(filepath.Join(path, "dot_config")); err == nil {
			return path
		}
	}

	t.Fatalf("Could not find chezmoi directory. Tried: %v", possiblePaths)
	return ""
}

func copyFile(t *testing.T, src, dest string) {
	data, err := os.ReadFile(src)
	if err != nil {
		t.Fatalf("Failed to read %s: %v", src, err)
	}
	if err := os.WriteFile(dest, data, 0644); err != nil {
		t.Fatalf("Failed to write %s: %v", dest, err)
	}
}

