# Signal Design System - Pure Unit Tests
#
# This file contains pure Nix unit tests that don't require shell evaluation.
# These tests use lib.runTests for fast, deterministic testing of library functions.

{
  pkgs,
  lib,
  self,
  signal-palette,
}:

let
  inherit (lib) runTests;
  signalLib = import ../../lib {
    inherit lib;
    inherit (signal-palette) palette;
    inherit (self.inputs) nix-colorizer;
  };

  # Helper to run pure Nix tests and create a derivation
  mkTest =
    name: testSets:
    let
      results = runTests testSets;
    in
    pkgs.runCommand "test-${name}" { } ''
      echo "Running ${name}..."
      ${
        if results == [ ] then
          ''
            echo "✓ All tests passed for ${name}"
            touch $out
          ''
        else
          ''
            echo "FAIL: Tests failed for ${name}"
            echo "${builtins.toJSON results}"
            exit 1
          ''
      }
    '';

in
{
  # ============================================================================
  # Library Function Tests
  # ============================================================================

  unit-lib-resolveThemeMode = mkTest "lib-resolve-theme-mode" {
    testAutoToDark = {
      expr = signalLib.resolveThemeMode "auto";
      expected = "dark";
    };
    testDarkToDark = {
      expr = signalLib.resolveThemeMode "dark";
      expected = "dark";
    };
    testLightToLight = {
      expr = signalLib.resolveThemeMode "light";
      expected = "light";
    };
  };

  unit-lib-isValidResolvedMode = mkTest "lib-is-valid-resolved-mode" {
    testDarkIsValid = {
      expr = signalLib.isValidResolvedMode "dark";
      expected = true;
    };
    testLightIsValid = {
      expr = signalLib.isValidResolvedMode "light";
      expected = true;
    };
    testAutoIsInvalid = {
      expr = signalLib.isValidResolvedMode "auto";
      expected = false;
    };
    testRandomIsInvalid = {
      expr = signalLib.isValidResolvedMode "random";
      expected = false;
    };
  };

  unit-lib-getThemeName = mkTest "lib-get-theme-name" {
    testDarkTheme = {
      expr = signalLib.getThemeName "dark";
      expected = "signal-dark";
    };
    testLightTheme = {
      expr = signalLib.getThemeName "light";
      expected = "signal-light";
    };
    testAutoResolvesToDark = {
      expr = signalLib.getThemeName "auto";
      expected = "signal-dark";
    };
  };

  unit-lib-getColors = mkTest "lib-get-colors" {
    testDarkHasStructure = {
      expr = builtins.attrNames (signalLib.getColors "dark");
      expected = [
        "accent"
        "categorical"
        "tonal"
      ];
    };
    testLightHasStructure = {
      expr = builtins.attrNames (signalLib.getColors "light");
      expected = [
        "accent"
        "categorical"
        "tonal"
      ];
    };
    testDarkHasTonal = {
      expr = builtins.hasAttr "tonal" (signalLib.getColors "dark");
      expected = true;
    };
    testLightHasAccent = {
      expr = builtins.hasAttr "accent" (signalLib.getColors "light");
      expected = true;
    };
  };

  unit-lib-getSyntaxColors = mkTest "lib-get-syntax-colors" {
    testDarkHasBackground = {
      expr = builtins.hasAttr "background" (signalLib.getSyntaxColors "dark");
      expected = true;
    };
    testDarkHasForeground = {
      expr = builtins.hasAttr "foreground" (signalLib.getSyntaxColors "dark");
      expected = true;
    };
    testDarkHasKeyword = {
      expr = builtins.hasAttr "keyword" (signalLib.getSyntaxColors "dark");
      expected = true;
    };
    testLightHasBackground = {
      expr = builtins.hasAttr "background" (signalLib.getSyntaxColors "light");
      expected = true;
    };
    testLightHasString = {
      expr = builtins.hasAttr "string" (signalLib.getSyntaxColors "light");
      expected = true;
    };
  };

  # ============================================================================
  # Brand Governance Tests
  # ============================================================================

  edge-case-brand-governance = mkTest "edge-case-brand-governance" {
    testFunctionalOverride = {
      expr =
        let
          result = signalLib.brandGovernance.mergeColors {
            policy = "functional-override";
            functionalColors = {
              primary = "#000000";
            };
            brandColors = { };
            decorativeBrandColors = {
              logo = "#FF0000";
            };
          };
        in
        builtins.hasAttr "primary" result && builtins.hasAttr "decorative" result;
      expected = true;
    };

    testSeparateLayer = {
      expr =
        let
          result = signalLib.brandGovernance.mergeColors {
            policy = "separate-layer";
            functionalColors = {
              primary = "#000000";
            };
            brandColors = {
              accent = "#00FF00";
            };
            decorativeBrandColors = {
              logo = "#FF0000";
            };
          };
        in
        builtins.hasAttr "primary" result
        && builtins.hasAttr "brand" result
        && builtins.hasAttr "decorative" result;
      expected = true;
    };

    testIntegrated = {
      expr =
        let
          result = signalLib.brandGovernance.mergeColors {
            policy = "integrated";
            functionalColors = {
              primary = "#000000";
            };
            brandColors = {
              accent = "#00FF00";
            };
            decorativeBrandColors = {
              logo = "#FF0000";
            };
          };
        in
        builtins.hasAttr "primary" result
        && builtins.hasAttr "accent" result
        && builtins.hasAttr "decorative" result;
      expected = true;
    };
  };

  # ============================================================================
  # Accessibility Tests
  # ============================================================================

  accessibility-contrast-estimation = mkTest "accessibility-contrast" {
    testHighContrast = {
      expr =
        let
          contrast = signalLib.accessibility.estimateContrast {
            foreground = {
              l = 0.9;
              c = 0.0;
              h = 0.0;
            };
            background = {
              l = 0.1;
              c = 0.0;
              h = 0.0;
            };
          };
        in
        contrast > 50.0;
      expected = true;
    };

    testMeetsMinimum = {
      expr = signalLib.accessibility.meetsMinimum {
        foreground = {
          l = 0.9;
          c = 0.0;
          h = 0.0;
        };
        background = {
          l = 0.1;
          c = 0.0;
          h = 0.0;
        };
        minimum = 60.0;
      };
      expected = true;
    };

    testLowContrastFails = {
      expr = signalLib.accessibility.meetsMinimum {
        foreground = {
          l = 0.5;
          c = 0.0;
          h = 0.0;
        };
        background = {
          l = 0.48;
          c = 0.0;
          h = 0.0;
        };
        minimum = 60.0;
      };
      expected = false;
    };
  };

  # ============================================================================
  # Color Manipulation Tests
  # ============================================================================

  color-manipulation-lightness = mkTest "color-lightness" {
    testLightnessIncrease = {
      expr =
        let
          color = {
            l = 0.5;
            c = 0.1;
            h = 180.0;
            hex = "#000000";
            hexRaw = "000000";
            rgb = {
              r = 0;
              g = 0;
              b = 0;
            };
          };
          adjusted = signalLib.colors.adjustLightness {
            inherit color;
            delta = 0.2;
          };
        in
        adjusted.l > color.l;
      expected = true;
    };

    testChromaPreserved = {
      expr =
        let
          color = {
            l = 0.5;
            c = 0.1;
            h = 180.0;
            hex = "#000000";
            hexRaw = "000000";
            rgb = {
              r = 0;
              g = 0;
              b = 0;
            };
          };
          adjusted = signalLib.colors.adjustLightness {
            inherit color;
            delta = 0.2;
          };
        in
        adjusted.c == color.c;
      expected = true;
    };

    testHuePreserved = {
      expr =
        let
          color = {
            l = 0.5;
            c = 0.1;
            h = 180.0;
            hex = "#000000";
            hexRaw = "000000";
            rgb = {
              r = 0;
              g = 0;
              b = 0;
            };
          };
          adjusted = signalLib.colors.adjustLightness {
            inherit color;
            delta = 0.2;
          };
        in
        adjusted.h == color.h;
      expected = true;
    };
  };

  color-manipulation-chroma = mkTest "color-chroma" {
    testChromaIncrease = {
      expr =
        let
          color = {
            l = 0.5;
            c = 0.1;
            h = 180.0;
            hex = "#000000";
            hexRaw = "000000";
            rgb = {
              r = 0;
              g = 0;
              b = 0;
            };
          };
          adjusted = signalLib.colors.adjustChroma {
            inherit color;
            delta = 0.05;
          };
        in
        adjusted.c > color.c;
      expected = true;
    };

    testLightnessPreserved = {
      expr =
        let
          color = {
            l = 0.5;
            c = 0.1;
            h = 180.0;
            hex = "#000000";
            hexRaw = "000000";
            rgb = {
              r = 0;
              g = 0;
              b = 0;
            };
          };
          adjusted = signalLib.colors.adjustChroma {
            inherit color;
            delta = 0.05;
          };
        in
        adjusted.l == color.l;
      expected = true;
    };

    testHuePreserved = {
      expr =
        let
          color = {
            l = 0.5;
            c = 0.1;
            h = 180.0;
            hex = "#000000";
            hexRaw = "000000";
            rgb = {
              r = 0;
              g = 0;
              b = 0;
            };
          };
          adjusted = signalLib.colors.adjustChroma {
            inherit color;
            delta = 0.05;
          };
        in
        adjusted.h == color.h;
      expected = true;
    };
  };

  # ============================================================================
  # Semantic Bridge Tests
  # ============================================================================

  unit-lib-semantic = import ../unit-lib-semantic.nix {
    inherit
      pkgs
      lib
      self
      signal-palette
      ;
  };
}
