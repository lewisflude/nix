# Signal Design System - Home Manager Activation Tests
#
# This file provides activation-package-level testing (similar to NMT)
# Tests verify that Home Manager configurations build correctly and
# generate the expected files with correct content.

{
  pkgs,
  lib,
  self,
  home-manager,
  signal-palette,
  nix-colorizer,
  system,
}:

let
  # Helper to create a test Home Manager configuration
  # Takes a list of attrsets - config attrsets go to HM, testScript attrsets are extracted
  mkActivationTest =
    name: modules:
    let
      # Separate config modules from test scripts
      configModules = builtins.filter (m: !(m ? testScript)) modules;
      testScripts = builtins.filter (m: m ? testScript) modules;

      # Build a minimal Home Manager configuration
      hmConfig = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          self.homeManagerModules.signal
          {
            home = {
              username = "test-user";
              homeDirectory = "/home/test-user";
              stateVersion = "24.11";
            };

            # Disable manual to speed up tests
            manual.manpages.enable = false;
            manual.html.enable = false;
            manual.json.enable = false;
          }
        ]
        ++ configModules;
      };

      # Extract the activation package
      activationPackage = hmConfig.activationPackage;

    in
    pkgs.runCommand "test-activation-${name}"
      {
        buildInputs = [
          pkgs.jq
          pkgs.gnugrep
        ];
      }
      ''
        echo "Testing Home Manager activation: ${name}"

        # The activation package contains all files that would be installed
        # We can inspect the generated files
        export HOME_FILES="${activationPackage}/home-files"

        if [ ! -d "$HOME_FILES" ]; then
          echo "ERROR: No home-files directory in activation package"
          echo "Available contents:"
          ls -la ${activationPackage}
          exit 1
        fi

        echo "✓ Activation package built successfully"
        echo "Home files directory: $HOME_FILES"

        # Make home-files available for test assertions
        export TEST_HOME="$HOME_FILES"

        # Source the test script
        ${lib.concatMapStringsSep "\n" (m: m.testScript or "") testScripts}

        touch $out
      '';

in
{
  # ============================================================================
  # Helix Editor Activation Tests
  # ============================================================================

  activation-helix-dark = mkActivationTest "helix-dark" [
    {
      programs.helix.enable = true;
      theming.signal = {
        enable = true;
        autoEnable = false; # Test explicit enable, not auto-theming
        mode = "dark";
        editors.helix.enable = true;
      };
    }
    {
      testScript = ''
          echo "Testing Helix dark mode configuration..."

          # Check config file exists
          test -f "$TEST_HOME/.config/helix/config.toml" || {
            echo "ERROR: helix config.toml not found"
            ls -la "$TEST_HOME/.config/" || true
            exit 1
          }

          # Check theme is set
          grep -q 'theme = "signal-dark"' "$TEST_HOME/.config/helix/config.toml" || {
            echo "ERROR: Theme not set to signal-dark"
            cat "$TEST_HOME/.config/helix/config.toml"
            exit 1
          }

          # Check theme file exists
          test -f "$TEST_HOME/.config/helix/themes/signal-dark.toml" || {
            echo "ERROR: signal-dark theme file not found"
            exit 1
          }

        # Verify background color
        echo "=== Checking theme file contents ==="
        if [ -f "$TEST_HOME/.config/helix/themes/signal-dark.toml" ]; then
          echo "Theme file exists, showing first 50 lines:"
          head -50 "$TEST_HOME/.config/helix/themes/signal-dark.toml"
        else
          echo "ERROR: Theme file not found"
          exit 1
        fi

        # Check if palette section exists with background color
        grep -q 'background = "#1e1f26"' "$TEST_HOME/.config/helix/themes/signal-dark.toml" || {
          echo "ERROR: Wrong background color in palette"
          grep "background" "$TEST_HOME/.config/helix/themes/signal-dark.toml" || echo "background not found"
          exit 1
        }

          echo "✓ Helix dark mode configuration correct"
      '';
    }
  ];

  activation-helix-light = mkActivationTest "helix-light" [
    {
      programs.helix.enable = true;
      theming.signal = {
        enable = true;
        autoEnable = false; # Test explicit enable, not auto-theming
        mode = "light";
        editors.helix.enable = true;
      };
    }
    {
      testScript = ''
          echo "Testing Helix light mode configuration..."

          grep -q 'theme = "signal-light"' "$TEST_HOME/.config/helix/config.toml" || {
            echo "ERROR: Theme not set to signal-light"
            exit 1
          }

          test -f "$TEST_HOME/.config/helix/themes/signal-light.toml" || {
            echo "ERROR: signal-light theme file not found"
            exit 1
          }

        grep -q 'background = "#f2f3f7"' "$TEST_HOME/.config/helix/themes/signal-light.toml" || {
          echo "ERROR: Wrong light mode background color"
          grep "background" "$TEST_HOME/.config/helix/themes/signal-light.toml" || echo "background not found"
          exit 1
        }

          echo "✓ Helix light mode configuration correct"
      '';
    }
  ];

  # ============================================================================
  # Alacritty Terminal Activation Tests
  # ============================================================================

  activation-alacritty-dark = mkActivationTest "alacritty-dark" [
    {
      programs.alacritty.enable = true;
      theming.signal = {
        enable = true;
        autoEnable = false; # Test explicit enable, not auto-theming
        mode = "dark";
        terminals.alacritty.enable = true;
      };
    }
    {
      testScript = ''
        echo "Testing Alacritty dark mode configuration..."

        test -f "$TEST_HOME/.config/alacritty/alacritty.toml" || {
          echo "ERROR: alacritty.toml not found"
          exit 1
        }

        grep -q 'background = "#1e1f26"' "$TEST_HOME/.config/alacritty/alacritty.toml" || {
          echo "ERROR: Wrong background color"
          cat "$TEST_HOME/.config/alacritty/alacritty.toml"
          exit 1
        }

        grep -q 'foreground = "#d4d5df"' "$TEST_HOME/.config/alacritty/alacritty.toml" || {
          echo "ERROR: Wrong foreground color"
          exit 1
        }

        # Verify ANSI colors exist
        grep -q '\[colors.normal\]' "$TEST_HOME/.config/alacritty/alacritty.toml" || {
          echo "ERROR: Missing normal colors section"
          exit 1
        }

        echo "✓ Alacritty dark mode configuration correct"
      '';
    }
  ];

  # ============================================================================
  # Ghostty Terminal Activation Tests
  # ============================================================================

  activation-ghostty-dark = mkActivationTest "ghostty-dark" [
    {
      programs.ghostty.enable = true;
      theming.signal = {
        enable = true;
        autoEnable = false; # Test explicit enable, not auto-theming
        mode = "dark";
        terminals.ghostty.enable = true;
      };
    }
    {
      testScript = ''
        echo "Testing Ghostty dark mode configuration..."

        test -f "$TEST_HOME/.config/ghostty/config" || {
          echo "ERROR: ghostty config not found"
          exit 1
        }

        grep -q 'background = 1e1f26' "$TEST_HOME/.config/ghostty/config" || {
          echo "ERROR: Wrong background color"
          cat "$TEST_HOME/.config/ghostty/config"
          exit 1
        }

        grep -q 'foreground = d4d5df' "$TEST_HOME/.config/ghostty/config" || {
          echo "ERROR: Wrong foreground color"
          exit 1
        }

        # Verify palette colors (Ghostty uses palette = N=RRGGBB format)
        for i in {0..15}; do
          grep -q "palette = $i=" "$TEST_HOME/.config/ghostty/config" || {
            echo "ERROR: Missing palette color $i"
            exit 1
          }
        done

        echo "✓ Ghostty dark mode configuration correct"
      '';
    }
  ];

  # ============================================================================
  # Multi-Module Integration Test
  # ============================================================================

  activation-multi-module = mkActivationTest "multi-module" [
    {
      programs = {
        helix.enable = true;
        alacritty.enable = true;
      };

      theming.signal = {
        enable = true;
        autoEnable = false; # Test explicit enable, not auto-theming
        mode = "dark";
        editors.helix.enable = true;
        terminals.alacritty.enable = true;
      };
    }
    {
      testScript = ''
        echo "Testing multi-module consistency..."

        # Both configs should exist
        test -f "$TEST_HOME/.config/helix/themes/signal-dark.toml" || {
          echo "ERROR: Helix theme not found"
          exit 1
        }

        test -f "$TEST_HOME/.config/alacritty/alacritty.toml" || {
          echo "ERROR: Alacritty config not found"
          exit 1
        }

        # Verify both have dark mode colors
        grep -q '"signal-dark"' "$TEST_HOME/.config/helix/config.toml" || {
          echo "ERROR: Helix not using signal-dark theme"
          exit 1
        }

        grep -q '#1e1f26' "$TEST_HOME/.config/alacritty/alacritty.toml" || {
          echo "ERROR: Alacritty not using dark mode colors"
          exit 1
        }

        echo "✓ Multi-module theming verified"
      '';
    }
  ];

  # ============================================================================
  # Auto-Enable Test
  # ============================================================================

  activation-auto-enable = mkActivationTest "auto-enable" [
    {
      programs = {
        helix.enable = true;
        alacritty.enable = true;
      };

      theming.signal = {
        enable = true;
        mode = "dark";
        # autoEnable is true by default - testing automatic theming
        # Not explicitly enabling individual modules
      };
    }
    {
      testScript = ''
        echo "Testing auto-enable functionality..."

        # Should automatically theme enabled programs
        test -f "$TEST_HOME/.config/helix/themes/signal-dark.toml" || {
          echo "ERROR: Auto-enable didn't theme Helix"
          exit 1
        }

        test -f "$TEST_HOME/.config/alacritty/alacritty.toml" || {
          echo "ERROR: Auto-enable didn't theme Alacritty"
          exit 1
        }

        echo "✓ Auto-enable working correctly"
      '';
    }
  ];
}
