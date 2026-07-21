# Signal Design System - Integration Tests
#
# This file contains shell-based integration tests that validate module structure,
# example configurations, and file existence. These tests use pkgs.runCommand.

{
  pkgs,
  lib,
  self,
  signal-palette,
}:

let
  signalLib = import ../../lib {
    inherit lib;
    inherit (signal-palette) palette;
    inherit (self.inputs) nix-colorizer;
  };

  # ============================================================================
  # Test Helpers
  # ============================================================================

  # Helper to check that a file exists
  assertFileExists = path: name: ''
    test -f ${path} || {
      echo "FAIL: ${name} not found"
      exit 1
    }
  '';

  # Helper to check that a file contains a pattern
  assertFileContains = path: pattern: description: ''
    ${pkgs.gnugrep}/bin/grep -q "${pattern}" ${path} || {
      echo "FAIL: ${description}"
      exit 1
    }
  '';

  # Helper to create a module structure test
  mkModuleTest =
    name: modulePath: programName:
    pkgs.runCommand "test-module-${name}" { } ''
      echo "Testing ${name} module..."

      ${assertFileExists modulePath "${name} module"}
      ${assertFileContains modulePath "programs.${programName}"
        "${name} module missing programs.${programName} config"
      }

      echo "✓ ${name} module structure is valid"
      touch $out
    '';

  # Helper to create an example validation test
  mkExampleTest =
    name: examplePath: requiredPattern:
    pkgs.runCommand "test-example-${name}" { } ''
      echo "Testing ${name} example..."

      ${assertFileExists examplePath "${name} example"}
      ${assertFileContains examplePath requiredPattern "${name} example missing required pattern"}

      echo "✓ ${name} example structure is valid"
      touch $out
    '';

  # Helper to create a theme resolution test
  mkThemeResolutionTest =
    name: modulePath: expectedPattern: description:
    pkgs.runCommand "test-theme-${name}" { } ''
      echo "Testing ${description}..."

      ${assertFileContains modulePath expectedPattern description}

      echo "✓ ${description}"
      touch $out
    '';

in
{
  # ============================================================================
  # Integration Tests - Example Configurations
  # ============================================================================

  integration-example-basic =
    mkExampleTest "basic" ../../examples/basic.nix
      "homeConfigurations.user";

  integration-example-full-desktop =
    mkExampleTest "full-desktop" ../../examples/full-desktop.nix
      "homeConfigurations";

  integration-example-custom-brand =
    mkExampleTest "custom-brand" ../../examples/custom-brand.nix
      "brandGovernance";

  # New examples - documentation heavy, validate they parse correctly
  integration-example-migrating = pkgs.runCommand "test-example-migrating" { } ''
    echo "Testing migrating example parses correctly..."

    # The example contains multiple configuration patterns in comments
    # Just verify it's a valid flake structure
    ${assertFileContains ../../examples/migrating-existing-config.nix "homeConfigurations"
      "migrating example"
    }
    ${assertFileContains ../../examples/migrating-existing-config.nix
      "signal.homeManagerModules.default"
      "migrating example"
    }
    ${assertFileContains ../../examples/migrating-existing-config.nix "theming.signal"
      "migrating example"
    }
    ${assertFileContains ../../examples/migrating-existing-config.nix "autoEnable" "migrating example"}

    echo "✓ migrating example has valid structure"
    touch $out
  '';

  integration-example-multi-machine = pkgs.runCommand "test-example-multi-machine" { } ''
    echo "Testing multi-machine example parses correctly..."

    # The example contains patterns for multiple machines
    # Verify it contains expected structure
    ${assertFileContains ../../examples/multi-machine.nix "homeConfigurations" "multi-machine example"}
    ${assertFileContains ../../examples/multi-machine.nix "user@desktop" "multi-machine example"}
    ${assertFileContains ../../examples/multi-machine.nix "user@laptop" "multi-machine example"}
    ${assertFileContains ../../examples/multi-machine.nix "user@server" "multi-machine example"}
    ${assertFileContains ../../examples/multi-machine.nix "theming.signal" "multi-machine example"}

    echo "✓ multi-machine example has valid structure"
    touch $out
  '';

  # ============================================================================
  # Module Tests - Individual Module Evaluation
  # ============================================================================

  module-common-evaluates = pkgs.runCommand "test-module-common" { } ''
    echo "Testing common module evaluation..."

    ${assertFileExists ../../modules/common/default.nix "common module"}
    ${assertFileContains ../../modules/common/default.nix "imports = map applyModule"
      "common module missing imports with importApply pattern"
    }

    echo "✓ common module structure is valid"
    touch $out
  '';

  module-helix-dark = mkModuleTest "helix" ../../modules/editors/helix.nix "helix";

  module-helix-light =
    mkThemeResolutionTest "helix-resolution" ../../modules/editors/helix.nix "resolveThemeMode"
      "helix module uses theme resolution";

  module-ghostty-evaluates = mkModuleTest "ghostty" ../../modules/terminals/ghostty.nix "ghostty";

  module-bat-evaluates = mkModuleTest "bat" ../../modules/cli/bat.nix "bat";

  module-fzf-evaluates = mkModuleTest "fzf" ../../modules/cli/fzf.nix "fzf";

  module-mpv-structure = mkModuleTest "mpv" ../../modules/media/mpv.nix "mpv";

  module-mpv-colors = pkgs.runCommand "test-module-mpv-colors" { } ''
    echo "Testing MPV module color configuration..."

    ${assertFileExists ../../modules/media/mpv.nix "mpv module"}

    # Check for OSD colors
    ${assertFileContains ../../modules/media/mpv.nix "osd-color" "mpv module missing osd-color"}
    ${assertFileContains ../../modules/media/mpv.nix "osd-back-color"
      "mpv module missing osd-back-color"
    }
    ${assertFileContains ../../modules/media/mpv.nix "osd-border-color"
      "mpv module missing osd-border-color"
    }

    # Check for subtitle colors
    ${assertFileContains ../../modules/media/mpv.nix "sub-color" "mpv module missing sub-color"}
    ${assertFileContains ../../modules/media/mpv.nix "sub-border-color"
      "mpv module missing sub-border-color"
    }
    ${assertFileContains ../../modules/media/mpv.nix "sub-back-color"
      "mpv module missing sub-back-color"
    }

    # Check for alpha channel helper function
    ${assertFileContains ../../modules/media/mpv.nix "hexWithAlpha"
      "mpv module missing hexWithAlpha helper"
    }

    echo "✓ MPV module has correct color configuration"
    touch $out
  '';

  module-gtk-evaluates = pkgs.runCommand "test-module-gtk" { } ''
    echo "Testing gtk module..."

    ${assertFileExists ../../modules/gtk/default.nix "gtk module"}
    ${assertFileExists ../../modules/gtk/theme.nix "gtk theme submodule"}
    ${assertFileContains ../../modules/gtk/theme.nix "gtk.gtk3.extraCss"
      "gtk module missing gtk config"
    }

    echo "✓ gtk module structure is valid"
    touch $out
  '';

  module-ironbar-evaluates = pkgs.runCommand "test-module-ironbar" { } ''
    echo "Testing ironbar module..."

    ${assertFileExists ../../modules/ironbar/default.nix "ironbar module"}

    echo "✓ ironbar module structure is valid"
    touch $out
  '';

  module-procs-evaluates = pkgs.runCommand "test-module-procs" { } ''
    echo "Testing procs module..."

    ${assertFileExists ../../modules/monitors/procs.nix "procs module"}

    # Check for TOML config generation
    ${assertFileContains ../../modules/monitors/procs.nix "writeText"
      "procs module missing config generation"
    }
    ${assertFileContains ../../modules/monitors/procs.nix "procs-config.toml"
      "procs module missing TOML config filename"
    }

    # Check for color sections
    ${assertFileContains ../../modules/monitors/procs.nix "\\[style.by_percentage\\]"
      "procs module missing percentage colors"
    }
    ${assertFileContains ../../modules/monitors/procs.nix "\\[style.by_state\\]"
      "procs module missing state colors"
    }
    ${assertFileContains ../../modules/monitors/procs.nix "\\[style.by_unit\\]"
      "procs module missing unit colors"
    }

    # Check config file placement
    ${assertFileContains ../../modules/monitors/procs.nix "xdg.configFile"
      "procs module missing xdg.configFile"
    }
    ${assertFileContains ../../modules/monitors/procs.nix "procs/config.toml"
      "procs module missing config path"
    }

    echo "✓ procs module has correct structure"
    touch $out
  '';

  module-satty-structure = pkgs.runCommand "test-module-satty-structure" { } ''
    echo "Testing Satty module structure..."

    ${assertFileExists ../../modules/apps/satty.nix "satty module"}

    # Check for TOML configuration generation
    ${assertFileContains ../../modules/apps/satty.nix "xdg.configFile"
      "satty module missing xdg.configFile"
    }
    ${assertFileContains ../../modules/apps/satty.nix "satty/config.toml"
      "satty module missing config path"
    }

    # Check for color palette
    ${assertFileContains ../../modules/apps/satty.nix "color-palette"
      "satty module missing color-palette section"
    }

    echo "✓ satty module has correct structure"
    touch $out
  '';

  module-satty-colors = pkgs.runCommand "test-module-satty-colors" { } ''
    echo "Testing Satty module color configuration..."

    ${assertFileExists ../../modules/apps/satty.nix "satty module"}

    # Check for color palette configuration
    ${assertFileContains ../../modules/apps/satty.nix "colorPalette ="
      "satty module missing colorPalette"
    }
    ${assertFileContains ../../modules/apps/satty.nix "customColors ="
      "satty module missing customColors"
    }

    # Check for Signal color usage
    ${assertFileContains ../../modules/apps/satty.nix "accent.secondary"
      "satty module missing accent colors"
    }
    ${assertFileContains ../../modules/apps/satty.nix "accent.danger"
      "satty module missing danger colors"
    }
    ${assertFileContains ../../modules/apps/satty.nix "accent.warning"
      "satty module missing warning colors"
    }

    # Check for TOML generator
    ${assertFileContains ../../modules/apps/satty.nix "generators.toTOML"
      "satty module missing TOML generator"
    }

    echo "✓ satty module has correct color configuration"
    touch $out
  '';

  # ============================================================================
  # Edge Case Tests - Option Combinations
  # ============================================================================

  edge-case-all-disabled = pkgs.runCommand "test-edge-case-all-disabled" { } ''
    echo "Testing module structure allows disabled state..."

    ${assertFileContains ../../modules/editors/helix.nix "mkIf"
      "helix should use mkIf for conditional config"
    }

    echo "✓ Modules properly guard configuration with mkIf"
    touch $out
  '';

  edge-case-multiple-terminals = pkgs.runCommand "test-edge-case-multiple-terminals" { } ''
    echo "Testing multiple terminal modules exist..."

    ${assertFileExists ../../modules/terminals/ghostty.nix "ghostty terminal"}
    ${assertFileExists ../../modules/terminals/alacritty.nix "alacritty terminal"}
    ${assertFileExists ../../modules/terminals/kitty.nix "kitty terminal"}
    ${assertFileExists ../../modules/terminals/wezterm.nix "wezterm terminal"}

    echo "✓ All terminal modules exist"
    touch $out
  '';

  edge-case-ironbar-profiles = pkgs.runCommand "test-edge-case-ironbar-profiles" { } ''
    echo "Testing ironbar profile options..."

    ${assertFileContains ../../modules/common/default.nix "compact"
      "ironbar profile 'compact' not documented"
    }
    ${assertFileContains ../../modules/common/default.nix "relaxed"
      "ironbar profile 'relaxed' not documented"
    }
    ${assertFileContains ../../modules/common/default.nix "spacious"
      "ironbar profile 'spacious' not documented"
    }

    echo "✓ All ironbar profiles are defined"
    touch $out
  '';

  # ============================================================================
  # Validation Tests - Theme Resolution Consistency
  # ============================================================================

  validation-theme-names = pkgs.runCommand "test-validation-theme-names" { } ''
    echo "Testing theme name consistency across modules..."

    ${assertFileContains ../../modules/cli/bat.nix "themeMode = signalLib.resolveThemeMode"
      "bat.nix should use signalLib.resolveThemeMode"
    }
    echo "✓ bat.nix uses themeMode"

    ${assertFileContains ../../modules/editors/helix.nix "themeMode = signalLib.resolveThemeMode"
      "helix.nix should use signalLib.resolveThemeMode"
    }
    echo "✓ helix.nix uses themeMode"

    # gtk/default.nix is now a meta-module using importApply
    ${assertFileContains ../../modules/gtk/theme.nix "themeMode = signalLib.resolveThemeMode"
      "gtk/theme.nix should use signalLib.resolveThemeMode"
    }
    echo "✓ gtk/theme.nix uses themeMode"

    ${assertFileContains ../../modules/common/default.nix "resolveThemeMode cfg.mode"
      "common/default.nix should resolve theme mode"
    }
    echo "✓ common/default.nix resolves mode"

    echo "✓ All theme name validation tests passed"
    touch $out
  '';

  validation-no-auto-theme-names = pkgs.runCommand "test-validation-no-auto-names" { } ''
    echo "Testing that no module uses 'signal-auto' as a theme name..."

    # Search for any occurrence of "signal-auto" in module files
    # Exclude comments (lines starting with #) from the search
    if ${pkgs.gnugrep}/bin/grep -r "signal-auto" ${../../modules} 2>/dev/null | ${pkgs.gnugrep}/bin/grep -v "^.*#.*signal-auto" | ${pkgs.gnugrep}/bin/grep -v "signal-auto\")"; then
      echo "FAIL: Found 'signal-auto' in module files - should use resolved theme"
      exit 1
    fi

    echo "✓ No modules use 'signal-auto' directly"
    touch $out
  '';

  # ============================================================================
  # Module Test - Fuzzel (Desktop App Launcher)
  # ============================================================================

  module-fuzzel-structure = pkgs.runCommand "test-module-fuzzel-structure" { } ''
    echo "Testing Fuzzel module structure..."

    ${assertFileExists ../../modules/desktop/fuzzel.nix "fuzzel module"}

    # Check for program configuration
    ${assertFileContains ../../modules/desktop/fuzzel.nix "programs.fuzzel"
      "fuzzel module missing programs.fuzzel config"
    }

    # Check for semantic bridge usage
    ${assertFileContains ../../modules/desktop/fuzzel.nix "semantic.ui"
      "fuzzel module should use semantic bridge"
    }
    ${assertFileContains ../../modules/desktop/fuzzel.nix "semantic.core"
      "fuzzel module should use semantic bridge"
    }
    ${assertFileContains ../../modules/desktop/fuzzel.nix "semantic.text"
      "fuzzel module should use semantic bridge"
    }

    # Check for color settings
    ${assertFileContains ../../modules/desktop/fuzzel.nix "colors = {"
      "fuzzel module missing colors configuration"
    }

    echo "✓ fuzzel module has correct structure"
    touch $out
  '';

  module-fuzzel-colors = pkgs.runCommand "test-module-fuzzel-colors" { } ''
    echo "Testing Fuzzel module color configuration..."

    ${assertFileExists ../../modules/desktop/fuzzel.nix "fuzzel module"}

    # Check for required color settings
    ${assertFileContains ../../modules/desktop/fuzzel.nix "background ="
      "fuzzel module missing background color"
    }
    ${assertFileContains ../../modules/desktop/fuzzel.nix "text =" "fuzzel module missing text color"}
    ${assertFileContains ../../modules/desktop/fuzzel.nix "match =" "fuzzel module missing match color"}
    ${assertFileContains ../../modules/desktop/fuzzel.nix "selection-background ="
      "fuzzel module missing selection-background color"
    }
    ${assertFileContains ../../modules/desktop/fuzzel.nix "border ="
      "fuzzel module missing border color"
    }

    # Check for alpha channel helper - ensure it's used correctly
    ${assertFileContains ../../modules/desktop/fuzzel.nix
      "withAlpha = color: alpha: signalLib.hexWithAlpha color alpha"
      "fuzzel module should pass color object (not color.hex) to signalLib.hexWithAlpha"
    }

    echo "✓ fuzzel module has correct color configuration"
    touch $out
  '';

  # ============================================================================
  # Module Test - Zellij (Terminal Multiplexer)
  # ============================================================================

  module-zellij-structure = pkgs.runCommand "test-module-zellij-structure" { } ''
    echo "Testing Zellij module structure..."

    ${assertFileExists ../../modules/multiplexers/zellij.nix "zellij module"}

    # Check for program configuration
    ${assertFileContains ../../modules/multiplexers/zellij.nix "programs.zellij"
      "zellij module missing programs.zellij config"
    }

    # Check for semantic bridge usage
    ${assertFileContains ../../modules/multiplexers/zellij.nix "semantic.core"
      "zellij module should use semantic bridge"
    }
    ${assertFileContains ../../modules/multiplexers/zellij.nix "semantic.status"
      "zellij module should use semantic bridge"
    }
    ${assertFileContains ../../modules/multiplexers/zellij.nix "semantic.multiplayer"
      "zellij module should use semantic bridge"
    }

    # Check for toZellijColor helper
    ${assertFileContains ../../modules/multiplexers/zellij.nix "toZellijColor ="
      "zellij module missing toZellijColor helper"
    }

    echo "✓ zellij module has correct structure"
    touch $out
  '';

  module-zellij-colors = pkgs.runCommand "test-module-zellij-colors" { } ''
    echo "Testing Zellij module color configuration..."

    ${assertFileExists ../../modules/multiplexers/zellij.nix "zellij module"}

    # Check for theme configuration
    ${assertFileContains ../../modules/multiplexers/zellij.nix "themes.signal"
      "zellij module missing signal theme"
    }

    # Check for multiplayer colors with correct parentheses
    ${assertFileContains ../../modules/multiplexers/zellij.nix "toZellijColor (semantic.multiplayer"
      "zellij module should properly parenthesize semantic.multiplayer calls"
    }

    # Check for color conversion usage
    ${assertFileContains ../../modules/multiplexers/zellij.nix "toZellijColor colors."
      "zellij module missing color conversions"
    }

    echo "✓ zellij module has correct color configuration"
    touch $out
  '';
}
