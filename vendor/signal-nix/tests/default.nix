# Signal Design System - Comprehensive Test Suite
#
# This file imports and aggregates all test categories for easy management.
# Tests are organized into:
#   - tests/unit/        - Pure Nix unit tests (lib.runTests)
#   - tests/integration/ - Shell-based validation tests (pkgs.runCommand)
#   - tests/nixos.nix    - NixOS-specific tests

{
  pkgs,
  lib,
  self,
  home-manager,
  signal-palette,
  system,
}:

let
  # Import unit tests (pure Nix evaluation)
  unitTests = import ./unit {
    inherit
      pkgs
      lib
      self
      signal-palette
      ;
  };

  # Import integration tests (shell-based validation)
  integrationTests = import ./integration {
    inherit
      pkgs
      lib
      self
      signal-palette
      ;
  };

  # Import comprehensive test suite (from comprehensive-test-suite.nix)
  comprehensiveTests = import ./comprehensive-test-suite.nix {
    inherit
      pkgs
      lib
      self
      home-manager
      signal-palette
      system
      ;
  };

in
{
  # ============================================================================
  # Unit Tests (Pure Nix - Fast)
  # ============================================================================
  # These tests use lib.runTests for pure function evaluation.
  # They are fast and deterministic with no shell dependencies.

  inherit (unitTests)
    # Library functions
    unit-lib-resolveThemeMode
    unit-lib-isValidResolvedMode
    unit-lib-getThemeName
    unit-lib-getColors
    unit-lib-getSyntaxColors

    # Brand governance
    edge-case-brand-governance

    # Accessibility
    accessibility-contrast-estimation

    # Color manipulation
    color-manipulation-lightness
    color-manipulation-chroma
    ;

  # ============================================================================
  # Integration Tests (Shell-Based - Slower)
  # ============================================================================
  # These tests use pkgs.runCommand with shell validation.
  # They verify module structure, file existence, and pattern matching.

  inherit (integrationTests)
    # Example configurations
    integration-example-basic
    integration-example-auto-enable
    integration-example-full-desktop
    integration-example-custom-brand
    integration-example-migrating
    integration-example-multi-machine

    # Module evaluation
    module-common-evaluates
    module-helix-dark
    module-helix-light
    module-ghostty-evaluates
    module-bat-evaluates
    module-fzf-evaluates
    module-mpv-structure
    module-mpv-colors
    module-gtk-evaluates
    module-ironbar-evaluates
    module-procs-evaluates
    module-satty-structure
    module-satty-colors
    module-fuzzel-structure
    module-fuzzel-colors
    module-zellij-structure
    module-zellij-colors

    # Edge cases
    edge-case-all-disabled
    edge-case-multiple-terminals
    edge-case-ironbar-profiles

    # Validation
    validation-theme-names
    validation-no-auto-theme-names
    ;

  # ============================================================================
  # Comprehensive Test Suite
  # ============================================================================
  # Additional tests from comprehensive-test-suite.nix

  inherit (comprehensiveTests)
    # Happy Path Tests
    happy-basic-dark-mode
    happy-basic-light-mode
    happy-auto-mode-defaults-dark
    happy-color-structure
    happy-syntax-colors-complete
    happy-brand-governance-functional-override

    # Edge Case Tests
    edge-empty-brand-colors
    edge-lightness-boundaries
    edge-chroma-boundaries
    edge-contrast-extreme-values
    edge-all-modules-disabled
    edge-ironbar-profiles

    # Error Handling Tests
    error-invalid-theme-mode
    error-brand-governance-invalid-policy
    error-color-manipulation-throws

    # Integration Tests
    integration-module-lib-interaction
    integration-colors-and-syntax
    integration-brand-with-colors
    integration-theme-resolution-consistency
    integration-auto-enable-logic
    integration-helix-builds
    integration-ghostty-builds
    integration-gtk-qt-theming

    # Performance Tests
    performance-color-lookups
    performance-theme-resolution-cached
    performance-large-brand-colors
    performance-module-evaluation

    # Security Tests
    security-color-hex-validation
    security-no-code-injection
    security-mode-enum-validation
    security-brand-policy-enum-validation
    security-no-path-traversal

    # Documentation Tests
    documentation-examples-valid-nix
    documentation-readme-references

    # Color Conversion Tests (nix-colorizer)
    color-conversion-hex-to-rgb
    color-conversion-hex-with-alpha
    color-conversion-validation
    ;
}
