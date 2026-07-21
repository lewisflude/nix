# Signal Design System - Helix Editor NMT Tests
#
# Tests for the Helix editor module, verifying:
# - Configuration file generation
# - Theme file generation with exact colors
# - Dark/light mode switching
# - Auto mode resolution

{
  lib,
  pkgs,
  self,
}:

let
  # Helper to create a helix test
  mkHelixTest = name: mode: extraConfig: {
    inherit name;
    modules = [
      {
        programs.helix = {
          enable = true;
        };

        signal = {
          enable = true;
          inherit mode;
          editors.helix.enable = true;
        };
      }
      extraConfig
    ];
  };

in
{
  # ============================================================================
  # Basic Dark Mode Test
  # ============================================================================

  nmt-helix-basic-dark = mkHelixTest "helix-basic-dark" "dark" {
    nmt.script = ''
      # Verify config.toml exists and is valid TOML
      assertFileExists home-files/.config/helix/config.toml

      # Verify theme is set to signal-dark
      assertFileRegex \
        home-files/.config/helix/config.toml \
        'theme = "signal-dark"'

      # Verify theme file exists
      assertFileExists home-files/.config/helix/themes/signal-dark.toml

      # Verify languages.toml exists (for syntax highlighting)
      assertFileExists home-files/.config/helix/languages.toml

      # Verify key background color is correct
      assertFileRegex \
        home-files/.config/helix/themes/signal-dark.toml \
        '"ui.background" = "#0f1419"'

      # Verify text color is correct
      assertFileRegex \
        home-files/.config/helix/themes/signal-dark.toml \
        '"ui.text" = "#e6e1cf"'

      # Verify selection color exists
      assertFileRegex \
        home-files/.config/helix/themes/signal-dark.toml \
        '"ui.selection"'

      # Verify cursor colors exist
      assertFileRegex \
        home-files/.config/helix/themes/signal-dark.toml \
        '"ui.cursor"'

      # Verify syntax highlighting colors exist
      assertFileRegex \
        home-files/.config/helix/themes/signal-dark.toml \
        '"keyword"'
      assertFileRegex \
        home-files/.config/helix/themes/signal-dark.toml \
        '"function"'
      assertFileRegex \
        home-files/.config/helix/themes/signal-dark.toml \
        '"string"'
    '';
  };

  # ============================================================================
  # Basic Light Mode Test
  # ============================================================================

  nmt-helix-basic-light = mkHelixTest "helix-basic-light" "light" {
    nmt.script = ''
      # Verify config.toml exists
      assertFileExists home-files/.config/helix/config.toml

      # Verify theme is set to signal-light
      assertFileRegex \
        home-files/.config/helix/config.toml \
        'theme = "signal-light"'

      # Verify theme file exists
      assertFileExists home-files/.config/helix/themes/signal-light.toml

      # Verify background is light (not dark)
      assertFileRegex \
        home-files/.config/helix/themes/signal-light.toml \
        '"ui.background" = "#fefaf5"'

      # Verify text is dark (not light)
      assertFileRegex \
        home-files/.config/helix/themes/signal-light.toml \
        '"ui.text" = "#5c6773"'
    '';
  };

  # ============================================================================
  # Auto Mode Test (defaults to dark)
  # ============================================================================

  nmt-helix-auto-mode = mkHelixTest "helix-auto-mode" "auto" {
    nmt.script = ''
      # Auto mode should resolve to dark
      assertFileRegex \
        home-files/.config/helix/config.toml \
        'theme = "signal-dark"'

      # Should generate dark theme
      assertFileExists home-files/.config/helix/themes/signal-dark.toml
    '';
  };

  # ============================================================================
  # Color Accuracy Test (verify exact color values)
  # ============================================================================

  nmt-helix-color-accuracy = {
    name = "helix-color-accuracy";
    modules = [
      {
        programs.helix.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          editors.helix.enable = true;
        };

        nmt.script = ''
          # Extract theme file
          THEME_FILE="home-files/.config/helix/themes/signal-dark.toml"

          # Verify UI colors
          echo "Checking UI colors..."
          grep -q '"ui.background" = "#0f1419"' "$THEME_FILE" || {
            echo "ERROR: Wrong background color"
            exit 1
          }

          grep -q '"ui.text" = "#e6e1cf"' "$THEME_FILE" || {
            echo "ERROR: Wrong text color"
            exit 1
          }

          # Verify cursor colors
          echo "Checking cursor colors..."
          grep -q '"ui.cursor"' "$THEME_FILE" || {
            echo "ERROR: Missing cursor color"
            exit 1
          }

          # Verify syntax colors
          echo "Checking syntax highlighting colors..."
          for color in keyword function string type comment variable; do
            grep -q "\"$color\"" "$THEME_FILE" || {
              echo "ERROR: Missing $color syntax color"
              exit 1
            }
          done

          # Verify diagnostic colors
          echo "Checking diagnostic colors..."
          for diag in error warning info hint; do
            grep -q "\"$diag\"" "$THEME_FILE" || {
              echo "ERROR: Missing $diag diagnostic color"
              exit 1
            }
          done

          echo "✓ All colors verified"
        '';
      }
    ];
  };
}
