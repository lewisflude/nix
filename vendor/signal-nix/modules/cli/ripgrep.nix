{
  signalLib,
  signalPalette,
  semantic,
  nix-colorizer,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
# CONFIGURATION METHOD: environment-variables (Tier 5)
# HOME-MANAGER MODULE: home.sessionVariables
# UPSTREAM SCHEMA: https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#colors
# SCHEMA VERSION: 14.1.0
# LAST VALIDATED: 2026-01-17
# NOTES: Ripgrep uses RIPGREP_CONFIG_PATH or command-line flags for colors.
#        We use environment variables for color configuration via RIPGREP_COLORS.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Helper to convert hex color to RGB triplet for ripgrep (R,G,B format)
  # Uses signalLib's RGB conversion which leverages nix-colorizer
  toRgbTriplet =
    color:
    let
      rgb = signalLib.hexToRgbCommaSeparated color;
    in
    rgb;

  # Check if ripgrep should be themed
  shouldTheme = cfg.cli.ripgrep.enable or false || cfg.autoEnable;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    home.sessionVariables = {
      # Ripgrep color configuration - using semantic bridge
      # Format: type:style:foreground:background:intense
      # We use fg: for foreground RGB colors
      RIPGREP_COLORS = lib.concatStringsSep ":" [
        "match:fg:${toRgbTriplet (semantic.vcs "modified" themeMode)}" # Matched text
        "match:style:bold" # Make matches bold
        "path:fg:${toRgbTriplet (semantic.vcs "modified" themeMode)}" # File paths
        "line:fg:${toRgbTriplet (semantic.vcs "added" themeMode)}" # Line numbers
        "column:fg:${toRgbTriplet (semantic.text "secondary" themeMode)}" # Column numbers
      ];
    };

    # Also set ripgrep to use colors by default
    home.shellAliases = mkIf shouldTheme {
      rg = "rg --color=auto";
    };
  };
}
