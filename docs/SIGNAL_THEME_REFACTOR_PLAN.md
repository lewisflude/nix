# Signal Theme Architecture Refactoring Plan

This document provides a detailed, task-by-task implementation plan for refactoring the Signal theme architecture to a higher, more maintainable standard.

## Overview

The refactoring is organized into 5 phases, with 68 total tasks. Each task is designed to be:

- **Small and atomic**: Can be completed independently
- **Testable**: Has clear success criteria
- **Backward compatible**: Maintains existing functionality during migration
- **Well-documented**: Includes code comments and documentation updates

## Phase 1: Foundation (17 tasks)

### Unified Options Module

#### Task 1.1: Create Base Options Module

**File**: `modules/shared/features/theming/options.nix`

**Implementation**:

```nix
{ lib }:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.theming.signal = {
    enable = mkEnableOption "Signal OKLCH color palette theme";

    mode = mkOption {
      type = types.enum [ "light" "dark" "auto" ];
      default = "dark";
      description = ''
        Color theme mode:
        - light: Use light mode colors
        - dark: Use dark mode colors
        - auto: Follow system preference (defaults to dark)
      '';
    };

    applications = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "Apply theme to this application";
        };
      });
      default = { };
      description = "Application-specific theme configuration";
    };
  };
}
```

**Success Criteria**:

- File created with base option structure
- Options match current implementation
- No evaluation errors

**Dependencies**: None

---

#### Task 1.2: Extract Brand Governance Options

**File**: `modules/shared/features/theming/options.nix` (add to existing)

**Implementation**: Add brandGovernance options section with:

- `policy` (enum: functional-override, separate-layer, integrated)
- `decorativeBrandColors` (attrsOf str)
- `brandColors` (attrsOf submodule with l, c, h, hex)

**Success Criteria**:

- All brand governance options extracted
- Type definitions match current implementation
- Documentation preserved

**Dependencies**: Task 1.1

---

#### Task 1.3: Extract Overrides Option (Deprecated)

**File**: `modules/shared/features/theming/options.nix` (add to existing)

**Implementation**: Add overrides option with deprecation warning:

```nix
overrides = mkOption {
  type = types.attrsOf (types.submodule { ... });
  default = { };
  description = ''
    Override specific palette colors. Use with caution.
    ?? DEPRECATED: For brand colors, use brandGovernance.brandColors instead.
  '';
};
```

**Success Criteria**:

- Overrides option extracted
- Deprecation warning added
- Backward compatibility maintained

**Dependencies**: Task 1.1

---

#### Task 1.4: Update NixOS Module to Use Shared Options

**File**: `modules/nixos/features/theming/default.nix`

**Implementation**:

```nix
{
  imports = [
    ../../../shared/features/theming/options.nix
  ];

  # Extend with NixOS-specific options
  options.theming.signal.applications = {
    fuzzel = { ... };
    # ... other NixOS apps
  };
}
```

**Success Criteria**:

- Module imports shared options
- NixOS-specific application options added
- No evaluation errors
- Existing functionality preserved

**Dependencies**: Tasks 1.1, 1.2, 1.3

---

#### Task 1.5: Update Home Manager Module to Use Shared Options

**File**: `home/common/theming/default.nix`

**Implementation**: Similar to Task 1.4, but for Home Manager

**Success Criteria**:

- Module imports shared options
- Home Manager-specific application options added
- No evaluation errors
- Existing functionality preserved

**Dependencies**: Tasks 1.1, 1.2, 1.3

---

#### Task 1.6: Add Option Definition Tests

**File**: `modules/shared/features/theming/tests/options.nix`

**Implementation**:

```nix
{ lib, ... }:
{
  name = "Signal theme options consistency";

  nodes = {
    nixos = { ... };
    home = { ... };
  };

  testScript = ''
    # Verify options are identical
    assert nixos.succeed("nix-instantiate --eval -E '...'")
    assert home.succeed("nix-instantiate --eval -E '...'")
  '';
}
```

**Success Criteria**:

- Tests verify option definitions match
- Tests pass for both platforms
- Tests integrated into flake checks

**Dependencies**: Tasks 1.4, 1.5

---

### Mode Resolution System

#### Task 1.7: Create Mode Resolution Module

**File**: `modules/shared/features/theming/mode.nix`

**Implementation**:

```nix
{ lib, config ? null }:
rec {
  # Resolve mode from config or default
  resolveMode = mode:
    if mode == "auto" then detectSystemMode config
    else if mode == "light" || mode == "dark" then mode
    else throw "Invalid mode: ${mode}";

  # Detect system preference
  detectSystemMode = config:
    # Check GTK settings, systemd, etc.
    # Default to dark if cannot detect
    "dark";

  # Validate mode
  isValidMode = mode: builtins.elem mode [ "light" "dark" "auto" ];
}
```

**Success Criteria**:

- Mode resolution functions implemented
- System detection logic added
- Validation functions work

**Dependencies**: None

---

#### Task 1.8: Implement System Preference Detection

**File**: `modules/shared/features/theming/mode.nix` (enhance)

**Implementation**: Add detection for:

- GTK settings (`gsettings get org.gnome.desktop.interface color-scheme`)
- systemd user environment variables
- XDG config files
- Fallback to dark mode

**Success Criteria**:

- Detection works on NixOS
- Detection works on nix-darwin
- Graceful fallback when detection fails

**Dependencies**: Task 1.7

---

#### Task 1.9: Add Mode Validation Functions

**File**: `modules/shared/features/theming/mode.nix` (enhance)

**Implementation**: Add functions for:

- Mode normalization
- Mode validation with helpful error messages
- Mode comparison

**Success Criteria**:

- Validation catches invalid modes
- Error messages are helpful
- Functions are well-tested

**Dependencies**: Task 1.7

---

#### Task 1.10: Update Platform Modules to Use Mode Resolution

**Files**:

- `modules/nixos/features/theming/default.nix`
- `home/common/theming/default.nix`

**Implementation**: Replace direct mode usage with `mode.resolveMode cfg.mode`

**Success Criteria**:

- Both modules use mode resolution
- Auto mode works correctly
- No regressions

**Dependencies**: Tasks 1.8, 1.9

---

#### Task 1.11: Add Mode Resolution Tests

**File**: `modules/shared/features/theming/tests/mode.nix`

**Implementation**: Test cases for:

- Light mode resolution
- Dark mode resolution
- Auto mode detection (mocked)
- Invalid mode handling

**Success Criteria**:

- All test cases pass
- Edge cases covered
- Tests integrated into CI

**Dependencies**: Task 1.10

---

### Theme Context System

#### Task 1.12: Create Theme Context Type

**File**: `modules/shared/features/theming/context.nix`

**Implementation**:

```nix
{ lib, ... }:
rec {
  # Theme context type
  themeContextType = types.submodule {
    options = {
      theme = mkOption { type = themeType; };
      mode = mkOption { type = types.enum [ "light" "dark" ]; };
      palette = mkOption { type = paletteType; };
      lib = mkOption { type = themeLibType; };
    };
  };

  # Create context from config
  createContext = { config, themeLib, palette, mode }:
    {
      theme = themeLib.generateTheme mode;
      inherit mode palette;
      lib = themeLib;
    };
}
```

**Success Criteria**:

- Context type defined
- Context creation function works
- Type safety enforced

**Dependencies**: None

---

#### Task 1.13: Implement Context Provider

**File**: `modules/shared/features/theming/context.nix` (enhance)

**Implementation**: Add provider function that:

- Validates theme is generated
- Ensures mode is resolved
- Provides context to modules

**Success Criteria**:

- Context provider works correctly
- Validation catches errors
- Clear error messages

**Dependencies**: Task 1.12

---

#### Task 1.14: Add Context Validation

**File**: `modules/shared/features/theming/context.nix` (enhance)

**Implementation**: Add validation for:

- Theme completeness
- Mode validity
- Required fields present

**Success Criteria**:

- Validation catches invalid contexts
- Helpful error messages
- Performance is acceptable

**Dependencies**: Task 1.13

---

#### Task 1.15: Update NixOS Module to Use Context

**File**: `modules/nixos/features/theming/default.nix`

**Implementation**: Replace `_module.args.signalPalette` with context system

**Success Criteria**:

- Context system integrated
- All application modules receive context
- No regressions

**Dependencies**: Tasks 1.13, 1.14

---

#### Task 1.16: Update Home Manager Module to Use Context

**File**: `home/common/theming/default.nix`

**Implementation**: Similar to Task 1.15

**Success Criteria**:

- Context system integrated
- All application modules receive context
- No regressions

**Dependencies**: Tasks 1.13, 1.14

---

#### Task 1.17: Update All Application Modules

**Files**: All application modules in both directories

**Implementation**: Change from:

```nix
{ signalPalette ? null, ... }:
let theme = signalPalette; in
```

To:

```nix
{ themeContext ? null, ... }:
let theme = themeContext.theme; in
```

**Success Criteria**:

- All modules updated
- No functionality lost
- Tests pass

**Dependencies**: Tasks 1.15, 1.16

---

#### Task 1.18: Add Backward Compatibility Shim

**File**: `modules/shared/features/theming/context.nix` (enhance)

**Implementation**: Add shim that:

- Detects old `_module.args.signalPalette` usage
- Converts to context automatically
- Emits deprecation warning

**Success Criteria**:

- Old code still works
- Warnings are clear
- Migration path documented

**Dependencies**: Task 1.17

---

## Phase 2: Application Organization (22 tasks)

### Application Registry

#### Task 2.1: Create Registry Structure

**File**: `modules/shared/features/theming/applications/registry.nix`

**Implementation**:

```nix
{ lib }:
rec {
  # Application metadata type
  applicationType = {
    name = string;
    platform = enum [ "nixos" "home" "both" ];
    category = enum [ "editor" "terminal" "desktop" "cli" ];
    description = string;
    dependencies = listOf string;
    module = path;
  };

  # Registry of all applications
  applications = {
    cursor = { ... };
    helix = { ... };
    # ... all applications
  };
}
```

**Success Criteria**:

- Registry structure defined
- All applications registered
- Metadata is complete

**Dependencies**: None

---

#### Task 2.2: Define Registry Entry Type

**File**: `modules/shared/features/theming/applications/registry.nix` (enhance)

**Implementation**: Create proper Nix types for registry entries

**Success Criteria**:

- Type safety enforced
- Validation works
- Documentation complete

**Dependencies**: Task 2.1

---

#### Task 2.3: Register All Applications

**File**: `modules/shared/features/theming/applications/registry.nix` (enhance)

**Implementation**: Add entries for:

- Editors: cursor, helix, zed
- Terminals: ghostty, zellij
- Desktop: gtk, mako, swaync, fuzzel, ironbar, swappy
- CLI: bat, fzf, lazygit, yazi

**Success Criteria**:

- All applications registered
- Metadata is accurate
- No duplicates

**Dependencies**: Task 2.2

---

#### Task 2.4: Create Registry Query Functions

**File**: `modules/shared/features/theming/applications/registry.nix` (enhance)

**Implementation**: Add functions:

- `getByPlatform`: Filter by platform
- `getByCategory`: Filter by category
- `getAll`: Get all applications
- `getByName`: Get specific application

**Success Criteria**:

- Query functions work correctly
- Performance is good
- Well-documented

**Dependencies**: Task 2.3

---

### Standard Application Interface

#### Task 2.5: Create Interface Definition

**File**: `modules/shared/features/theming/applications/interface.nix`

**Implementation**:

```nix
{ lib }:
rec {
  # Standard application interface
  applicationInterface = {
    enable = bool;
    themeConfig = attrs;  # Application-specific config
    themeFiles = listOf path;  # Generated theme files
    themeDependencies = listOf package;  # Required packages
    platform = enum [ "nixos" "home" "both" ];
  };

  # Validate application conforms to interface
  validateApplication = app: ...;
}
```

**Success Criteria**:

- Interface defined
- Validation works
- Documentation complete

**Dependencies**: None

---

#### Task 2.6: Define Interface Type

**File**: `modules/shared/features/theming/applications/interface.nix` (enhance)

**Implementation**: Create Nix types for interface

**Success Criteria**:

- Type safety enforced
- Validation catches errors
- Clear error messages

**Dependencies**: Task 2.5

---

#### Task 2.7: Create Interface Validation

**File**: `modules/shared/features/theming/applications/interface.nix` (enhance)

**Implementation**: Add validation function that checks:

- Required fields present
- Types are correct
- Dependencies are valid

**Success Criteria**:

- Validation works
- Helpful error messages
- Performance acceptable

**Dependencies**: Task 2.6

---

### Application Reorganization

#### Tasks 2.8-2.15: Create Directories and Move Files

**Implementation**:

- Create `editors/`, `terminals/`, `desktop/`, `cli/` directories
- Move application modules to appropriate directories
- Update all imports

**Success Criteria**:

- Files moved correctly
- Imports updated
- No broken references

**Dependencies**: Task 2.3

---

#### Task 2.16: Update Application Modules to Use Interface

**Files**: All application modules

**Implementation**: Refactor each module to:

- Use standard interface
- Accept theme context
- Return interface-compliant structure

**Success Criteria**:

- All modules conform to interface
- Validation passes
- Functionality preserved

**Dependencies**: Tasks 2.7, 2.15

---

#### Task 2.17: Update Platform Module Imports

**Files**:

- `modules/nixos/features/theming/default.nix`
- `home/common/theming/default.nix`

**Implementation**: Update imports to reference new shared locations

**Success Criteria**:

- Imports updated
- Applications load correctly
- No regressions

**Dependencies**: Task 2.16

---

#### Task 2.18: Add Migration Guide

**File**: ~~`docs/SIGNAL_THEME_MIGRATION.md`~~ (Removed - migration complete)

**Implementation**: Document:

- What changed
- How to update configs
- Breaking changes

**Note**: This migration guide was removed after Phase 5 cleanup as all deprecated patterns have been removed.

- Migration examples

**Success Criteria**:

- Guide is complete
- Examples work
- Clear migration path

**Dependencies**: Task 2.17

---

## Phase 3: Validation & Testing (18 tasks)

### Validation Layer

#### Task 3.1: Create Validation Framework

**File**: `modules/shared/features/theming/validation.nix`

**Implementation**:

```nix
{ lib, ... }:
rec {
  # Validation result type
  validationResult = {
    passed = bool;
    errors = listOf string;
    warnings = listOf string;
  };

  # Run all validations
  validateTheme = theme: ...;
}
```

**Success Criteria**:

- Framework created
- Result type defined
- Extensible design

**Dependencies**: None

---

#### Task 3.2: Implement WCAG Contrast Calculation

**File**: `modules/shared/features/theming/validation.nix` (enhance)

**Implementation**: Add functions for:

- Relative luminance calculation
- Contrast ratio calculation
- WCAG AA/AAA compliance checking

**Success Criteria**:

- Calculations are correct
- Matches WCAG spec
- Well-tested

**Dependencies**: Task 3.1

---

#### Task 3.3: Implement APCA Contrast Calculation

**File**: `modules/shared/features/theming/validation.nix` (enhance)

**Implementation**: Add APCA calculation (if nix-colorizer supports it, otherwise placeholder)

**Success Criteria**:

- APCA calculation works
- Falls back gracefully
- Documentation explains limitations

**Dependencies**: Task 3.2

---

#### Task 3.4: Create Contrast Validation Function

**File**: `modules/shared/features/theming/validation.nix` (enhance)

**Implementation**: Add `validateContrast` that:

- Checks text/background combinations
- Validates semantic token pairs
- Reports violations

**Success Criteria**:

- Validation works correctly
- Reports are helpful
- Performance is good

**Dependencies**: Tasks 3.2, 3.3

---

#### Task 3.5: Create Theme Completeness Validation

**File**: `modules/shared/features/theming/validation.nix` (enhance)

**Implementation**: Add function that checks:

- All semantic tokens present
- Required color formats available
- No missing mappings

**Success Criteria**:

- Catches incomplete themes
- Clear error messages
- Fast execution

**Dependencies**: Task 3.1

---

#### Task 3.6: Create Accessibility Validation

**File**: `modules/shared/features/theming/validation.nix` (enhance)

**Implementation**: Combine all accessibility checks:

- Contrast validation
- Color blindness checks
- Readability metrics

**Success Criteria**:

- Comprehensive checks
- Actionable reports
- Well-documented

**Dependencies**: Tasks 3.4, 3.5

---

#### Task 3.7: Integrate Validation into Theme Generation

**File**: `modules/shared/features/theming/lib.nix` (enhance)

**Implementation**: Add validation hooks to `generateTheme`:

- Optional validation on generation
- Configurable strictness
- Validation reports

**Success Criteria**:

- Validation integrated
- Configurable
- No performance regression

**Dependencies**: Task 3.6

---

#### Task 3.8: Add Validation Options

**File**: `modules/shared/features/theming/options.nix` (enhance)

**Implementation**: Add options:

- `enableValidation` (bool)
- `strictMode` (bool)
- `validationLevel` (enum: basic, standard, strict)

**Success Criteria**:

- Options added
- Integrated with validation
- Documentation complete

**Dependencies**: Task 3.7

---

#### Task 3.9: Create Validation Report Generator

**File**: `modules/shared/features/theming/validation.nix` (enhance)

**Implementation**: Add function that generates:

- Human-readable reports
- Machine-readable JSON
- Summary statistics

**Success Criteria**:

- Reports are clear
- Multiple formats supported
- Useful for debugging

**Dependencies**: Task 3.6

---

### Testing Infrastructure

#### Task 3.10: Create Test Directory Structure

**Files**: Create `modules/shared/features/theming/tests/` with subdirectories

**Success Criteria**:

- Directory structure created
- Organized by test type
- Ready for test files

**Dependencies**: None

---

#### Tasks 3.11-3.17: Create Test Files

**Implementation**: Create test files for:

- `palette.nix`: Palette generation tests
- `semantic.nix`: Semantic mapping tests
- `mode.nix`: Mode resolution tests
- `validation.nix`: Validation function tests
- `applications.nix`: Application integration tests
- `snapshots.nix`: Snapshot tests for generated files

**Success Criteria**:

- Tests are comprehensive
- All tests pass
- Good coverage

**Dependencies**: Task 3.10

---

#### Task 3.18: Add Test Runner Integration

**File**: `tests/theming.nix` (enhance)

**Implementation**: Integrate new tests into existing test infrastructure

**Success Criteria**:

- Tests run via `nix flake check`
- CI integration works
- Fast execution

**Dependencies**: Tasks 3.11-3.17

---

#### Task 3.19: Add CI Integration

**File**: `.github/workflows/theming-tests.yml` (or similar)

**Implementation**: Add CI job that:

- Runs all theme tests
- Reports failures
- Caches test results

**Success Criteria**:

- CI runs tests automatically
- Failures are reported
- Fast feedback

**Dependencies**: Task 3.18

---

## Phase 4: Advanced Features (11 tasks)

### Theme Factory Enhancements

#### Task 4.1: Create Theme Factory Pattern

**File**: `modules/shared/features/theming/lib.nix` (enhance)

**Implementation**: Add `createThemeFactory` function that:

- Provides composable theme creation
- Supports overrides
- Enables extensions

**Success Criteria**:

- Factory pattern works
- Composable and flexible
- Well-documented

**Dependencies**: None

---

#### Task 4.2: Implement Override Composition

**File**: `modules/shared/features/theming/lib.nix` (enhance)

**Implementation**: Add override system:

- Merge brand colors
- Apply custom colors
- Preserve base theme

**Success Criteria**:

- Overrides work correctly
- No conflicts
- Performance good

**Dependencies**: Task 4.1

---

#### Task 4.3: Add Extension Points System

**File**: `modules/shared/features/theming/lib.nix` (enhance)

**Implementation**: Add hooks for:

- Pre-generation
- Post-generation
- Custom transformations

**Success Criteria**:

- Extension points work
- Well-documented
- Flexible

**Dependencies**: Task 4.1

---

#### Task 4.4: Implement Theme Variant Support

**File**: `modules/shared/features/theming/lib.nix` (enhance)

**Implementation**: Add variant system:

- High contrast
- Reduced motion
- Color-blind friendly

**Success Criteria**:

- Variants work
- Generated correctly
- Well-tested

**Dependencies**: Task 4.1

---

#### Task 4.5: Add Variant Generation Functions

**File**: `modules/shared/features/theming/lib.nix` (enhance)

**Implementation**: Add functions to transform base palette:

- Increase contrast
- Reduce saturation
- Adjust hues

**Success Criteria**:

- Transformations work
- Mathematically sound
- Accessible

**Dependencies**: Task 4.4

---

#### Task 4.6: Integrate Validation Hooks

**File**: `modules/shared/features/theming/lib.nix` (enhance)

**Implementation**: Add automatic validation:

- On theme generation
- Configurable strictness
- Error reporting

**Success Criteria**:

- Validation integrated
- Configurable
- No performance issues

**Dependencies**: Tasks 3.7, 4.1

---

#### Task 4.7: Add Theme Caching

**File**: `modules/shared/features/theming/lib.nix` (enhance)

**Implementation**: Add caching for:

- Generated themes
- Validation results
- Computed values

**Success Criteria**:

- Caching works
- Performance improved
- Cache invalidation correct

**Dependencies**: Task 4.1

---

### Brand Governance Enhancements

#### Task 4.8: Enhance Brand Governance with Validation

**File**: `modules/shared/features/theming/lib.nix` (enhance)

**Implementation**: Add automatic contrast validation when integrating brand colors

**Success Criteria**:

- Validation works
- Warnings are clear
- Prevents accessibility issues

**Dependencies**: Tasks 3.4, 4.1

---

#### Task 4.9: Add Brand Color Transformation Utilities

**File**: `modules/shared/features/theming/lib.nix` (enhance)

**Implementation**: Add functions to:

- Convert hex to OKLCH
- Validate brand colors
- Suggest accessible alternatives

**Success Criteria**:

- Transformations work
- Validation accurate
- Suggestions helpful

**Dependencies**: Task 4.8

---

#### Task 4.10: Implement Multiple Brand Layers

**File**: `modules/shared/features/theming/options.nix` (enhance)

**Implementation**: Support for:

- Primary brand
- Secondary brand
- Multiple brand sets

**Success Criteria**:

- Multiple layers work
- No conflicts
- Well-documented

**Dependencies**: Task 4.8

---

#### Task 4.11: Add Brand Color Accessibility Validation

**File**: `modules/shared/features/theming/validation.nix` (enhance)

**Implementation**: Add specific validation for brand colors:

- Contrast checks
- Accessibility warnings
- Compliance reports

**Success Criteria**:

- Validation works
- Reports are helpful
- Prevents issues

**Dependencies**: Tasks 3.6, 4.9

---

### Documentation Generation

#### Task 4.12: Create Documentation Generator

**File**: `modules/shared/features/theming/docs/generator.nix`

**Implementation**: Create generator that:

- Extracts options from options.nix
- Generates markdown documentation
- Updates existing docs

**Success Criteria**:

- Generator works
- Documentation is accurate
- Auto-updates work

**Dependencies**: None

---

#### Task 4.13: Auto-generate Application List

**File**: `modules/shared/features/theming/docs/generator.nix` (enhance)

**Implementation**: Extract application list from registry.nix

**Success Criteria**:

- List is accurate
- Auto-updated
- Well-formatted

**Dependencies**: Tasks 2.3, 4.12

---

#### Task 4.14: Auto-generate Color Palette Documentation

**File**: `modules/shared/features/theming/docs/generator.nix` (enhance)

**Implementation**: Generate palette docs from palette.nix

**Success Criteria**:

- Documentation accurate
- Includes all colors
- Well-formatted

**Dependencies**: Task 4.12

---

#### Task 4.15: Create Architecture Diagram

**File**: `docs/reference/signal-theme-architecture.md`

**Implementation**: Document module relationships, data flow, and architecture

**Success Criteria**:

- Diagram is clear
- Relationships documented
- Up-to-date

**Dependencies**: Phase 1-3 completion

---

#### Task 4.16: Update Main Documentation

**File**: `docs/SIGNAL_THEME.md`

**Implementation**: Update with:

- New architecture
- Usage examples
- Migration guide links

**Success Criteria**:

- Documentation complete
- Examples work
- Clear and helpful

**Dependencies**: Task 4.15

---

## Phase 5: Cleanup & Polish (8 tasks)

### Task 5.1: Remove Deprecated Patterns

**Files**: All modules

**Implementation**: Remove `_module.args.signalPalette` pattern after migration period

**Success Criteria**:

- Old patterns removed
- No broken code
- Clean codebase

**Dependencies**: Task 1.18 (after migration period)

---

### Task 5.2: Remove Old Application Locations

**Files**: Old application directories

**Implementation**: Remove after confirming all imports updated

**Success Criteria**:

- Old files removed
- No broken references
- Clean structure

**Dependencies**: Task 2.17

---

### Task 5.3: Clean Up Duplicate Code

**Files**: Platform modules

**Implementation**: Remove any remaining duplication

**Success Criteria**:

- No duplication
- Code is DRY
- Maintainable

**Dependencies**: Phase 1-4 completion

---

### Task 5.4: Add Deprecation Warnings

**Files**: All modules

**Implementation**: Add warnings for old patterns with migration instructions

**Success Criteria**:

- Warnings are clear
- Migration path documented
- Helpful messages

**Dependencies**: None

---

### Task 5.5: Update All Documentation

**Files**: All documentation files

**Implementation**: Ensure all docs reflect new architecture

**Success Criteria**:

- Documentation accurate
- Examples work
- Complete coverage

**Dependencies**: Phase 1-4 completion

---

### Task 5.6: Run Full Test Suite

**Action**: Run all tests

**Success Criteria**:

- All tests pass
- No regressions
- Good coverage

**Dependencies**: Phase 3 completion

---

### Task 5.7: Update Examples

**Files**: `docs/examples/`

**Implementation**: Update all examples to use new patterns

**Success Criteria**:

- Examples work
- Use new patterns
- Well-documented

**Dependencies**: Task 5.5

---

### Task 5.8: Create User Migration Guide

**File**: ~~`docs/SIGNAL_THEME_MIGRATION.md`~~ (Removed - migration complete)

**Implementation**: Comprehensive guide for users upgrading

**Success Criteria**:

- Guide is complete
- Clear steps
- Examples provided

**Dependencies**: Phase 1-4 completion

---

## Implementation Guidelines

### Task Size

Each task should be completable in 1-4 hours. If a task is larger, break it down further.

### Testing

- Write tests alongside implementation
- Ensure backward compatibility
- Test edge cases

### Documentation

- Update relevant docs with each task
- Add code comments
- Include examples

### Code Quality

- Follow existing code style
- Use proper Nix types
- Add validation where appropriate

### Dependencies

- Respect task dependencies
- Complete phases in order where possible
- Test after each phase

## Success Metrics

- **Zero Regressions**: All existing functionality preserved
- **Improved Maintainability**: Reduced duplication, better organization
- **Better Testability**: Comprehensive test coverage
- **Enhanced Extensibility**: Easy to add new applications and features
- **Documentation Quality**: Complete, accurate, helpful documentation

## Timeline Estimate

- **Phase 1**: 2-3 weeks (foundation)
- **Phase 2**: 2-3 weeks (organization)
- **Phase 3**: 2-3 weeks (validation & testing)
- **Phase 4**: 2-3 weeks (advanced features)
- **Phase 5**: 1 week (cleanup)

**Total**: 9-13 weeks for complete implementation

## Notes

- Tasks can be worked on in parallel where dependencies allow
- Some tasks may need iteration based on findings
- User feedback should be incorporated throughout
- Migration period should be generous to allow users to adapt
