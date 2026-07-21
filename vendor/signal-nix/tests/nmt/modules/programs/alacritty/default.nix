# Signal Design System - Alacritty Terminal NMT Tests
#
# Tests for the Alacritty terminal module, verifying:
# - Configuration file generation (TOML format)
# - Color scheme accuracy
# - ANSI color palette (16 colors)
# - Dark/light mode switching

{
  lib,
  pkgs,
  self,
}:

let
  mkAlacrittyTest = name: mode: extraConfig: {
    inherit name;
    modules = [
      {
        programs.alacritty = {
          enable = true;
        };

        signal = {
          enable = true;
          inherit mode;
          terminals.alacritty.enable = true;
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

  nmt-alacritty-basic-dark = mkAlacrittyTest "alacritty-basic-dark" "dark" {
    nmt.script = ''
      # Verify config file exists
      assertFileExists home-files/.config/alacritty/alacritty.toml

      # Verify it's valid TOML (should parse without error)
      ${pkgs.remarshal}/bin/remarshal -if toml -of json \
        home-files/.config/alacritty/alacritty.toml > /dev/null || {
        echo "ERROR: Invalid TOML in alacritty.toml"
        exit 1
      }

      # Verify background color
      assertFileRegex \
        home-files/.config/alacritty/alacritty.toml \
        'background = "#0f1419"'

      # Verify foreground color
      assertFileRegex \
        home-files/.config/alacritty/alacritty.toml \
        'foreground = "#e6e1cf"'

      # Verify cursor colors
      assertFileRegex \
        home-files/.config/alacritty/alacritty.toml \
        '\[colors.cursor\]'
    '';
  };

  # ============================================================================
  # Basic Light Mode Test
  # ============================================================================

  nmt-alacritty-basic-light = mkAlacrittyTest "alacritty-basic-light" "light" {
    nmt.script = ''
      # Verify config file exists
      assertFileExists home-files/.config/alacritty/alacritty.toml

      # Verify light background
      assertFileRegex \
        home-files/.config/alacritty/alacritty.toml \
        'background = "#fefaf5"'

      # Verify dark foreground (reversed from dark mode)
      assertFileRegex \
        home-files/.config/alacritty/alacritty.toml \
        'foreground = "#5c6773"'
    '';
  };

  # ============================================================================
  # ANSI Color Palette Test
  # ============================================================================

  nmt-alacritty-ansi-colors = {
    name = "alacritty-ansi-colors";
    modules = [
      {
        programs.alacritty.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          terminals.alacritty.enable = true;
        };

        nmt.script = ''
          CONFIG="home-files/.config/alacritty/alacritty.toml"

          echo "Verifying ANSI color palette..."

          # Check that normal colors section exists
          grep -q '\[colors.normal\]' "$CONFIG" || {
            echo "ERROR: Missing [colors.normal] section"
            exit 1
          }

          # Check all 8 normal colors
          for color in black red green yellow blue magenta cyan white; do
            grep -q "$color = " "$CONFIG" || {
              echo "ERROR: Missing normal.$color"
              exit 1
            }
          done

          # Check that bright colors section exists
          grep -q '\[colors.bright\]' "$CONFIG" || {
            echo "ERROR: Missing [colors.bright] section"
            exit 1
          }

          # Check all 8 bright colors
          for color in black red green yellow blue magenta cyan white; do
            # Count occurrences (should be 2: one in normal, one in bright)
            count=$(grep -c "$color = " "$CONFIG")
            if [ "$count" -lt 2 ]; then
              echo "ERROR: Missing bright.$color (found only $count occurrences)"
              exit 1
            fi
          done

          # Verify colors are hex format
          echo "Verifying hex color format..."
          grep -E '(black|red|green|yellow|blue|magenta|cyan|white) = "#[0-9a-fA-F]{6}"' "$CONFIG" > /dev/null || {
            echo "ERROR: Colors not in proper hex format"
            exit 1
          }

          echo "✓ All 16 ANSI colors present and valid"
        '';
      }
    ];
  };
}
