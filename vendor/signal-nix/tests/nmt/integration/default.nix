# Signal Design System - Integration Tests
#
# Tests that verify cross-module interactions and system-wide behavior

{
  lib,
  pkgs,
  self,
}:

{
  # ============================================================================
  # Multi-Module Test
  # ============================================================================

  nmt-integration-multi-module = {
    name = "integration-multi-module";
    modules = [
      {
        # Enable multiple applications
        programs = {
          helix.enable = true;
          alacritty.enable = true;
          bat.enable = true;
          fzf.enable = true;
        };

        signal = {
          enable = true;
          mode = "dark";

          # Enable Signal theming for all
          editors.helix.enable = true;
          terminals.alacritty.enable = true;
          cli.bat.enable = true;
          cli.fzf.enable = true;
        };

        nmt.script = ''
          echo "Testing multi-module consistency..."

          # Verify all configs exist
          assertFileExists home-files/.config/helix/config.toml
          assertFileExists home-files/.config/alacritty/alacritty.toml
          assertFileExists home-files/.config/bat/config

          # Extract background colors from different modules
          HELIX_BG=$(grep 'ui.background' home-files/.config/helix/themes/signal-dark.toml | grep -oE '#[0-9a-fA-F]{6}' | head -1)
          ALACRITTY_BG=$(grep 'background =' home-files/.config/alacritty/alacritty.toml | grep -oE '#[0-9a-fA-F]{6}')

          echo "Helix background: $HELIX_BG"
          echo "Alacritty background: $ALACRITTY_BG"

          # Verify colors are consistent
          if [ "$HELIX_BG" != "$ALACRITTY_BG" ]; then
            echo "ERROR: Background colors inconsistent across modules"
            echo "  Helix:    $HELIX_BG"
            echo "  Alacritty: $ALACRITTY_BG"
            exit 1
          fi

          echo "✓ Colors consistent across all modules"
        '';
      }
    ];
  };

  # ============================================================================
  # Auto-Enable Test
  # ============================================================================

  nmt-integration-auto-enable = {
    name = "integration-auto-enable";
    modules = [
      {
        programs = {
          helix.enable = true;
          alacritty.enable = true;
        };

        signal = {
          enable = true;
          mode = "dark";
          autoEnable = true;
          # Note: NOT explicitly enabling individual modules
        };

        nmt.script = ''
          echo "Testing auto-enable functionality..."

          # With autoEnable, modules should be themed automatically
          assertFileExists home-files/.config/helix/themes/signal-dark.toml
          assertFileExists home-files/.config/alacritty/alacritty.toml

          # Verify they have Signal colors
          assertFileRegex \
            home-files/.config/helix/config.toml \
            'theme = "signal-dark"'

          assertFileRegex \
            home-files/.config/alacritty/alacritty.toml \
            'background = "#0f1419"'

          echo "✓ Auto-enable working correctly"
        '';
      }
    ];
  };

  # ============================================================================
  # Color Consistency Test
  # ============================================================================

  nmt-integration-color-consistency = {
    name = "integration-color-consistency";
    modules = [
      {
        programs = {
          helix.enable = true;
          alacritty.enable = true;
          kitty.enable = true;
        };

        signal = {
          enable = true;
          mode = "dark";
          editors.helix.enable = true;
          terminals.alacritty.enable = true;
          terminals.kitty.enable = true;
        };

        nmt.script = ''
          echo "Testing color consistency across all terminals and editors..."

          # Define expected dark mode colors
          EXPECTED_BG="#0f1419"
          EXPECTED_FG="#e6e1cf"

          # Check Helix
          grep -q "$EXPECTED_BG" home-files/.config/helix/themes/signal-dark.toml || {
            echo "ERROR: Helix background color mismatch"
            exit 1
          }

          # Check Alacritty
          grep -q "background = \"$EXPECTED_BG\"" home-files/.config/alacritty/alacritty.toml || {
            echo "ERROR: Alacritty background color mismatch"
            exit 1
          }

          # Check Kitty
          grep -q "background $EXPECTED_BG" home-files/.config/kitty/kitty.conf || {
            echo "ERROR: Kitty background color mismatch"
            exit 1
          }

          echo "✓ All applications use consistent Signal colors"
        '';
      }
    ];
  };
}
