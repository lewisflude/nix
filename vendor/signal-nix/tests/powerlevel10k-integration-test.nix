# Integration test for powerlevel10k theming
# Verifies that:
# 1. Signal colors are exported correctly
# 2. Auto-detection works for zsh + powerlevel10k
# 3. Color values match semantic expectations
{
  pkgs,
  lib,
  ...
}:
let
  # Import signal-nix module
  signalModule = import ../modules/common/default.nix {
    inherit (import ../. { system = pkgs.system; }) palette;
    inherit (pkgs) nix-colorizer;
    signalLib = import ../lib {
      inherit lib;
      inherit (import ../. { system = pkgs.system; }) palette;
      inherit (pkgs) nix-colorizer;
    };
  };

  # Test configuration with zsh + powerlevel10k
  testConfig = lib.evalModules {
    modules = [
      signalModule
      {
        # Enable signal-nix with autoEnable
        theming.signal = {
          enable = true;
          autoEnable = true;
          mode = "dark";
        };

        # Simulate zsh with powerlevel10k plugin
        programs.zsh = {
          enable = true;
          plugins = [
            {
              name = "powerlevel10k";
              src = pkgs.zsh-powerlevel10k;
            }
          ];
        };

        # Simulate themed terminal
        programs.ghostty.enable = true;
      }
    ];
  };

  # Extract the exported colors
  exportedColors = testConfig.config.theming.signal.colors.powerlevel10k or null;

  # Validation checks
  checks = {
    # Check 1: Colors are exported
    colorsExported = exportedColors != null;

    # Check 2: Required color keys exist
    hasRequiredKeys =
      exportedColors != null
      && (builtins.hasAttr "success" exportedColors)
      && (builtins.hasAttr "warning" exportedColors)
      && (builtins.hasAttr "error" exportedColors)
      && (builtins.hasAttr "vcs_clean" exportedColors)
      && (builtins.hasAttr "vcs_modified" exportedColors)
      && (builtins.hasAttr "dir_default" exportedColors);

    # Check 3: Colors are valid ANSI codes (0-255)
    colorsValid =
      exportedColors != null
      && (lib.all (
        key:
        let
          value = exportedColors.${key};
        in
        lib.isInt value && value >= 0 && value <= 255
      ) (builtins.attrNames exportedColors));

    # Check 4: Semantic mappings are correct
    semanticMappingsCorrect =
      exportedColors != null
      && exportedColors.success == 2 # ANSI green
      && exportedColors.warning == 3 # ANSI yellow
      && exportedColors.error == 1 # ANSI red
      && exportedColors.info == 6 # ANSI cyan
      && exportedColors.vcs_clean == 2 # Green for clean
      && exportedColors.vcs_modified == 3 # Yellow for modified
      && exportedColors.vcs_conflicted == 1; # Red for conflicts
  };

  # Generate test report
  testReport = builtins.toJSON {
    testName = "powerlevel10k-integration";
    passed = lib.all lib.id (builtins.attrValues checks);
    checks = checks;
    exportedColors = exportedColors;
  };
in
pkgs.runCommand "powerlevel10k-integration-test" { } ''
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Powerlevel10k Integration Test"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  ${lib.concatMapStringsSep "\n" (
    name:
    let
      result = checks.${name};
      icon = if result then "✅" else "❌";
    in
    "echo '${icon} ${name}: ${if result then "PASS" else "FAIL"}'"
  ) (builtins.attrNames checks)}

  echo ""
  echo "Exported Colors:"
  ${
    if exportedColors != null then
      lib.concatMapStringsSep "\n" (key: "echo '  - ${key} = ${toString exportedColors.${key}}'") (
        builtins.attrNames exportedColors
      )
    else
      "echo '  (none)'"
  }

  echo ""
  ${
    if lib.all lib.id (builtins.attrValues checks) then
      ''
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ✅ ALL TESTS PASSED"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        touch $out
      ''
    else
      ''
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ❌ TESTS FAILED"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Test Report:"
        echo '${testReport}'
        echo ""
        exit 1
      ''
  }
''
