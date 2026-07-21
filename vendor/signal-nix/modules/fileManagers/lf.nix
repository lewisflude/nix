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
# CONFIGURATION METHOD: raw-config (Tier 4)
# HOME-MANAGER MODULE: programs.lf.extraConfig
# UPSTREAM SCHEMA: https://pkg.go.dev/github.com/gokcehan/lf
# SCHEMA VERSION: 31
# LAST VALIDATED: 2026-01-17
# NOTES: lf uses shell-style config. Home-Manager provides extraConfig for
#        custom commands and settings. We set colors via ANSI codes.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  # lf uses ANSI color codes (0-7 for basic, 8-15 for bright)
  # We rely on terminal ANSI colors being themed by Signal

  # Check if lf should be themed
  shouldTheme = signalLib.shouldThemeApp "lf" [
    "fileManagers"
    "lf"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.lf.extraConfig = ''
      # Signal theme for lf
      # Uses ANSI color codes that map to terminal colors

      # Format: LF_COLORS="<type>=<color>"
      # Colors: 0-7 (basic), 8-15 (bright), or RGB

      # File type colors (these use terminal ANSI which Signal themes)
      set ifs "\n"

      # Use terminal colors for different file types
      # These will be themed by the terminal emulator (kitty, alacritty, etc.)
      # which Signal already themes

      # Icons and colors are handled by the terminal's ANSI palette
      # No need to set specific colors as lf respects LS_COLORS
    '';

    # Set LS_COLORS for lf (same as bash module)
    home.sessionVariables = mkIf shouldTheme {
      LF_COLORS = "*.md=33:*.txt=37:*.zip=31:*.tar=31:*.gz=31";
    };
  };
}
