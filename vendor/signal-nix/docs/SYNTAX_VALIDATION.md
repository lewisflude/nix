# Syntax Validation

Tools and processes to prevent syntax errors in Signal modules.

## Overview

Signal uses multiple validation layers to catch syntax errors before they reach users:

1. **Nix evaluation** - Built-in Nix syntax checking
2. **Statix** - Nix linter for common issues
3. **Custom validators** - Signal-specific checks
4. **CI/CD checks** - Automated testing on every commit

## Quick Validation

### Validate Your Changes

```bash
# Run all validation checks
nix flake check

# Run Statix linter
statix check

# Test specific module
nix build .#checks.x86_64-linux.module-<app>
```

## Validation Tools

### 1. Nix Built-in Validation

Nix catches basic syntax errors:

```bash
# Check syntax
nix-instantiate --parse <file>.nix

# Evaluate expression
nix eval .#<expression>

# Build with trace
nix build --show-trace
```

**Common errors caught:**
- Missing semicolons
- Unmatched braces
- Invalid attribute names
- Type errors

### 2. Statix Linter

Statix catches Nix anti-patterns:

```bash
# Check all files
statix check

# Check specific file
statix check modules/editors/helix.nix

# Auto-fix issues
statix fix
```

**Configuration:** `statix.toml`

```toml
[check]
# Disabled checks
disabled = [
  "empty_pattern",  # Allow empty patterns
]
```

**Common issues caught:**
- Unused variables
- Empty let bindings
- Redundant patterns
- Deprecated syntax

### 3. Custom Validators

Signal includes custom validation scripts:

#### No Hardcoded Colors

```bash
# Check for hardcoded colors
./scripts/lint-colors.sh
```

Scans for:
- Hex colors: `#rrggbb`
- RGB: `rgb(r, g, b)`
- OKLCH: `oklch(l c h)`

**Example output:**
```
❌ Found hardcoded color in modules/editors/helix.nix:45
   foreground = "#c5cdd8";

✅ Should use semantic bridge:
   foreground = (semantic.core "foreground" mode).hex;
```

#### Semantic Reference Validation

```bash
# Validate semantic references
nix build .#checks.x86_64-linux.validation-semantic-references
```

Checks:
- All semantic categories exist
- All reference names are valid
- No broken mappings

#### Module Metadata Validation

```bash
# Check module metadata
./scripts/validate-metadata.sh
```

Verifies:
- Required metadata comments present
- Tier classification correct
- Schema URLs valid
- Dates in correct format

### 4. Pre-Commit Hooks

Automatically run checks before committing:

```bash
# Install pre-commit hooks
nix develop -c pre-commit install

# Run hooks manually
nix develop -c pre-commit run --all-files
```

**Configured hooks:**
- Nix syntax check
- Statix linting
- Color validation
- Formatting check

## Module Validation

### Required Metadata

Every module must include this metadata block:

```nix
{
  config,
  lib,
  signalLib,
  semantic,
  ...
}:
# CONFIGURATION METHOD: <tier-name>
# HOME-MANAGER MODULE: programs.<app>
# UPSTREAM SCHEMA: <schema-url>
# SCHEMA VERSION: <version>
# LAST VALIDATED: YYYY-MM-DD
# NOTES: <additional-context>

let
  # ... implementation
```

**Validation:**
```bash
./scripts/validate-metadata.sh modules/<category>/<app>.nix
```

### Module Structure Validation

Modules must follow this structure:

```nix
{
  config,
  lib,
  signalLib,
  semantic,
  ...
}:
# Metadata comments

let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  mode = signalLib.resolveThemeMode cfg.mode;

  # Color mappings
  colors = {
    # Use semantic bridge
    background = (semantic.core "background" mode).hex;
    foreground = (semantic.core "foreground" mode).hex;
  };

  # shouldTheme logic
  shouldTheme =
    cfg.<category>.<app>.enable ||
    (cfg.autoEnable && (config.programs.<app>.enable or false));
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.<app> = {
      # Configuration
    };
  };
}
```

**Validation:**
```bash
./scripts/validate-structure.sh modules/<category>/<app>.nix
```

## Color Validation

### No Hardcoded Colors

**Rule:** Never hardcode color values

❌ **Bad:**
```nix
programs.kitty.settings = {
  foreground = "#c5cdd8";
  background = "#0a0d12";
};
```

✅ **Good:**
```nix
let
  colors = {
    foreground = (semantic.core "foreground" mode).hex;
    background = (semantic.core "background" mode).hex;
  };
in
{
  programs.kitty.settings = colors;
}
```

**Validation:**
```bash
./scripts/lint-colors.sh modules/<category>/<app>.nix
```

### Semantic Bridge Usage

**Rule:** Use semantic bridge for all colors

❌ **Bad:**
```nix
foreground = signalColors.tonal."text-Lc75".hex;
```

✅ **Good:**
```nix
foreground = (semantic.core "foreground" mode).hex;
```

**Validation:**
```bash
nix build .#checks.x86_64-linux.validation-semantic-references
```

### Color Format Validation

**Rule:** Use correct format for each application

```nix
# Hex format (most common)
color = (semantic.core "foreground" mode).hex;  # "#c5cdd8"

# RGB space-separated (Zellij)
color = signalLib.hexToRgbSpaceSeparated
  (semantic.core "foreground" mode).hex;  # "197 205 216"

# RRGGBBAA format (Fuzzel)
color = signalLib.hexWithAlpha
  (semantic.core "foreground" mode).hex 1.0;  # "c5cdd8ff"
```

## Configuration Validation

### Option Validation

Ensure options are properly defined:

```bash
# Check option definition
nix eval .#homeManagerModules.default.options.theming.signal.<category>.<app>

# Verify option type
nix eval .#homeManagerModules.default.options.theming.signal.<category>.<app>.type
```

### Type Checking

Use proper types for options:

```nix
options.theming.signal.<category>.<app> = {
  enable = lib.mkEnableOption "Signal theme for <app>";  # bool

  # Not:
  enable = lib.mkOption { type = lib.types.bool; };  # Verbose
};
```

### Assertion Validation

Add assertions for critical conditions:

```nix
config = mkIf (cfg.enable && shouldTheme) {
  assertions = [
    {
      assertion = config.programs.<app>.enable or false;
      message = "<app> must be enabled to apply Signal theme";
    }
  ];

  programs.<app> = {
    # Configuration
  };
};
```

## Testing Validation

### Module Tests

Every module should have a test:

```bash
# Test module evaluation
nix build .#checks.x86_64-linux.module-<app>

# Test both modes
nix build .#checks.x86_64-linux.module-<app>-dark
nix build .#checks.x86_64-linux.module-<app>-light
```

### Integration Tests

Test modules together:

```bash
# Test full configuration
nix build .#checks.x86_64-linux.integration-full-desktop
```

### Validation Tests

Run validation suite:

```bash
# All validation tests
nix flake check

# Specific validation
nix build .#checks.x86_64-linux.validation-no-hardcoded-colors
nix build .#checks.x86_64-linux.validation-semantic-references
nix build .#checks.x86_64-linux.validation-color-consistency
```

## CI/CD Validation

### GitHub Actions

Automated checks on every commit:

```yaml
name: Validation
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v22

      - name: Nix flake check
        run: nix flake check

      - name: Statix lint
        run: nix develop -c statix check

      - name: Color validation
        run: nix develop -c ./scripts/lint-colors.sh

      - name: Metadata validation
        run: nix develop -c ./scripts/validate-metadata.sh
```

### Pre-Merge Checks

Required checks before merging:
- ✅ All tests pass
- ✅ No hardcoded colors
- ✅ Statix lint passes
- ✅ Metadata valid
- ✅ Documentation updated

## Common Validation Errors

### Error: Hardcoded Color Found

```
❌ Found hardcoded color in modules/editors/helix.nix:45
   foreground = "#c5cdd8";
```

**Fix:**
```nix
foreground = (semantic.core "foreground" mode).hex;
```

### Error: Invalid Semantic Reference

```
❌ Invalid semantic reference: semantic.core "invalid-name" mode
```

**Fix:** Check [semantic-bridge-guide.md](semantic-bridge-guide.md) for valid names

### Error: Missing Metadata

```
❌ Missing required metadata in modules/editors/helix.nix
```

**Fix:** Add metadata block:
```nix
# CONFIGURATION METHOD: Tier 1 - Native Theme
# HOME-MANAGER MODULE: programs.helix
# UPSTREAM SCHEMA: https://docs.helix-editor.com/themes.html
# SCHEMA VERSION: 24.07
# LAST VALIDATED: 2026-01-20
```

### Error: Incorrect shouldTheme Logic

```
❌ Module doesn't respect autoEnable
```

**Fix:**
```nix
shouldTheme =
  cfg.<category>.<app>.enable ||
  (cfg.autoEnable && (config.programs.<app>.enable or false));
```

## Validation Checklist

Before submitting a PR:

- [ ] Run `nix flake check` - All tests pass
- [ ] Run `statix check` - No linter warnings
- [ ] Run `./scripts/lint-colors.sh` - No hardcoded colors
- [ ] Run `./scripts/validate-metadata.sh` - Metadata valid
- [ ] Test dark mode - Colors apply correctly
- [ ] Test light mode - Colors apply correctly
- [ ] Test autoEnable - Works as expected
- [ ] Test explicit enable - Works as expected
- [ ] Test explicit disable - Respects disable
- [ ] Documentation updated - README, theming-reference, etc.

## Tools Reference

### Available Scripts

```bash
# Validation scripts
./scripts/lint-colors.sh              # Check for hardcoded colors
./scripts/validate-metadata.sh        # Validate module metadata
./scripts/validate-structure.sh       # Check module structure
./scripts/validate-pr.sh              # Full PR validation

# Test scripts
./run-tests.sh                        # Run all tests
./scripts/test-module.sh <app>        # Test specific module

# Development tools
statix check                          # Nix linter
nix flake check                       # All checks
nix develop -c pre-commit run         # Pre-commit hooks
```

### Configuration Files

```
statix.toml                           # Statix configuration
.pre-commit-config.yaml               # Pre-commit hooks
flake.nix                             # Test definitions
```

## Next Steps

- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Test suite documentation
- **[CONTRIBUTING_APPLICATIONS.md](../CONTRIBUTING_APPLICATIONS.md)** - Add new applications
- **[Architecture](architecture.md)** - Understand the codebase
- **[Troubleshooting](troubleshooting.md)** - Debug issues
