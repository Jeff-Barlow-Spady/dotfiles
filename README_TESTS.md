# Testing

This directory contains both validation scripts and unit tests for the dotfiles setup.

## Validation Scripts

These scripts check the structure and syntax of the configuration:

- **`test.sh`** (Linux/macOS) - Validates directory structure, template syntax, OS isolation, and run scripts
- **`test.ps1`** (Windows) - Same validation for Windows PowerShell

Run validation:
```bash
# Linux/macOS
./test.sh

# Windows
.\test.ps1
```

## Test Types

### 1. Unit Tests (Waffle CLI)

The waffle CLI has Go unit tests that can run without a full system:

```bash
cd waffle
go test -v ./...
```

Or with coverage:
```bash
cd waffle
make test-cover
```

Tests cover:
- Path detection logic (`ChezmoiDataPath`)
- Data file updates (`UpdateChezmoiData`)
- Theme discovery (`GetThemes`)
- Embedded theme loading (`GetEmbeddedTheme`)
- Theme file writing (`WriteThemeToPath`)
- Command structure (verifies no `chezmoi apply` calls)

### 2. Integration Tests (Chezmoi + Waffle)

Integration tests verify the complete workflow between waffle and chezmoi:

```bash
cd chezmoi
go test -v -run TestIntegration
```

These tests verify:
- **`TestWaffleChezmoiIntegration`** - Full workflow: waffle updates data → chezmoi reads → templates render
- **`TestTemplateRendering`** - Templates render correctly with mock data
- **`TestFullWorkflow`** - Complete user workflow simulation
- **`TestRunScriptExecution`** - Run scripts are properly structured and would execute
- **`TestOSIsolation`** - Windows/Linux configs are properly isolated
- **`TestThemeTriggerMechanism`** - Theme changes trigger run scripts

These tests use temporary directories and mock chezmoi instances, so they don't require a full system setup.

### 3. Template Validation

Template syntax validation is done via the validation scripts (`test.sh` / `test.ps1`). These check:
- Template syntax correctness
- OS condition isolation
- Theme variable usage
- Run script naming conventions

You can also use chezmoi's built-in verification:
```bash
chezmoi verify
```

## Running All Tests

```bash
# From CONFIGS directory

# 1. Validation scripts (structure checks)
cd chezmoi && ./test.sh

# 2. Waffle unit tests (code logic)
cd ../waffle && go test -v ./...

# 3. Integration tests (waffle + chezmoi workflow)
cd ../chezmoi && go test -v ./...
```

## CI/CD Integration

These tests are designed to run in CI without requiring a full system setup:

1. **Structure validation** - `test.sh` / `test.ps1` (checks file structure and syntax)
2. **Unit tests** - `go test` in waffle directory (tests code logic)
3. **Integration tests** - `go test` in chezmoi directory (tests waffle + chezmoi workflow)
4. **Template syntax** - Validation scripts check template syntax

**Requirements for integration tests:**
- `chezmoi` binary in PATH (can be installed in CI)
- No full system setup needed - uses temporary directories and mock instances

No VM or fresh machine required - all tests run with mocked data and temporary directories.

