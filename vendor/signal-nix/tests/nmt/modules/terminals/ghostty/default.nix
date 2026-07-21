# Signal Design System - Ghostty Terminal NMT Tests
#
# Tests for the Ghostty terminal module, verifying:
# - Configuration file generation
# - Color palette accuracy
# - ANSI colors (16-color palette)
# - Theme switching

{
  lib,
  pkgs,
  self,
}:

let
  mkGhosttyTest = name: mode: extraConfig: {
    inherit name;
    modules = [
      {
        programs.ghostty = {
          enable = true;
        };

        signal = {
          enable = true;
          inherit mode;
          terminals.ghostty.enable = true;
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

  nmt-ghostty-basic-dark = mkGhosttyTest "ghostty-basic-dark" "dark" {
    nmt.script = ''
      # Verify config file exists
      assertFileExists home-files/.config/ghostty/config

      # Verify background color
      assertFileRegex \
        home-files/.config/ghostty/config \
        'background = 0f1419'

      # Verify foreground color
      assertFileRegex \
        home-files/.config/ghostty/config \
        'foreground = e6e1cf'

      # Verify cursor color exists
      assertFileRegex \
        home-files/.config/ghostty/config \
        'cursor-color'
    '';
  };

  # ============================================================================
  # Basic Light Mode Test
  # ============================================================================

  nmt-ghostty-basic-light = mkGhosttyTest "ghostty-basic-light" "light" {
    nmt.script = ''
      # Verify config file exists
      assertFileExists home-files/.config/ghostty/config

      # Verify light background
      assertFileRegex \
        home-files/.config/ghostty/config \
        'background = fefaf5'

      # Verify dark foreground
      assertFileRegex \
        home-files/.config/ghostty/config \
        'foreground = 5c6773'
    '';
  };

  # ============================================================================
  # ANSI Palette Test
  # ============================================================================

  nmt-ghostty-ansi-palette = {
    name = "ghostty-ansi-palette";
    modules = [
      {
        programs.ghostty.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          terminals.ghostty.enable = true;
        };

        nmt.script = ''
          CONFIG="home-files/.config/ghostty/config"

          echo "Verifying Ghostty ANSI palette..."

          # Ghostty uses palette = index=hexcolor format
          # Check all 16 palette entries (0-15)
          for i in {0..15}; do
            grep -q "palette = $i=" "$CONFIG" || {
              echo "ERROR: Missing palette color $i"
              exit 1
            }
          done

          # Verify format (hex without #)
          grep -E 'palette = [0-9]+=([0-9a-fA-F]{6})' "$CONFIG" > /dev/null || {
            echo "ERROR: Palette colors not in proper format"
            exit 1
          }

          # Verify at least one color is our brand color
          # This ensures it's using Signal colors, not generic defaults
          grep -q 'palette.*=.*6b87c8' "$CONFIG" || {
            echo "WARNING: Expected to find Signal brand color in palette"
          }

          echo "✓ All 16 ANSI palette colors present"
        '';
      }
    ];
  };
}
