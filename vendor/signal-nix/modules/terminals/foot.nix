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
# CONFIGURATION METHOD: ini-config (Tier 2)
# HOME-MANAGER MODULE: programs.foot.settings
# UPSTREAM SCHEMA: https://codeberg.org/dnkl/foot
# SCHEMA VERSION: 1.17.2
# LAST VALIDATED: 2026-01-17
# NOTES: Foot uses INI-style config. Home-Manager provides settings attrset
#        that gets serialized to foot.ini format.
#        Uses semantic bridge for consistent color mappings.
let
  inherit (lib) mkIf mkDefault;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Core colors using semantic bridge
  colors = {
    background = semantic.core "background" themeMode;
    foreground = semantic.core "foreground" themeMode;
    cursor = semantic.core "cursor" themeMode;
    selection-bg = semantic.core "selection-bg" themeMode;
    selection-fg = semantic.core "selection-fg" themeMode;
  };

  # ANSI colors using semantic terminal mappings
  ansiColors = {
    # Normal colors (0-7)
    black = semantic.terminal "ansi-black" themeMode;
    red = semantic.terminal "ansi-red" themeMode;
    green = semantic.terminal "ansi-green" themeMode;
    yellow = semantic.terminal "ansi-yellow" themeMode;
    blue = semantic.terminal "ansi-blue" themeMode;
    magenta = semantic.terminal "ansi-magenta" themeMode;
    cyan = semantic.terminal "ansi-cyan" themeMode;
    white = semantic.terminal "ansi-white" themeMode;

    # Bright colors (8-15)
    bright-black = semantic.terminal "ansi-bright-black" themeMode;
    bright-red = semantic.terminal "ansi-bright-red" themeMode;
    bright-green = semantic.terminal "ansi-bright-green" themeMode;
    bright-yellow = semantic.terminal "ansi-bright-yellow" themeMode;
    bright-blue = semantic.terminal "ansi-bright-blue" themeMode;
    bright-magenta = semantic.terminal "ansi-bright-magenta" themeMode;
    bright-cyan = semantic.terminal "ansi-bright-cyan" themeMode;
    bright-white = semantic.terminal "ansi-bright-white" themeMode;
  };

  # Foot uses hex colors without #
  toFootColor = color: lib.removePrefix "#" color.hex;

  # Check if foot should be themed
  shouldTheme = signalLib.shouldThemeApp "foot" [
    "terminals"
    "foot"
  ] cfg config;

  # Platform guard - Foot is Linux-only (Wayland terminal)
  platformOk = signalLib.platform.guard pkgs "foot";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    programs.foot.settings = {
      main = {
        # Font and general settings (user can override)
        # We only set colors
      };

      cursor = {
        color = mkDefault "${toFootColor colors.background} ${toFootColor colors.cursor}";
      };

      colors = {
        # Basic colors
        background = mkDefault (toFootColor colors.background);
        foreground = mkDefault (toFootColor colors.foreground);

        # Selection
        selection-foreground = mkDefault (toFootColor colors.selection-fg);
        selection-background = mkDefault (toFootColor colors.selection-bg);

        # URLs
        urls = mkDefault (toFootColor colors.cursor);

        # Regular colors (0-7)
        regular0 = mkDefault (toFootColor ansiColors.black); # black
        regular1 = mkDefault (toFootColor ansiColors.red); # red
        regular2 = mkDefault (toFootColor ansiColors.green); # green
        regular3 = mkDefault (toFootColor ansiColors.yellow); # yellow
        regular4 = mkDefault (toFootColor ansiColors.blue); # blue
        regular5 = mkDefault (toFootColor ansiColors.magenta); # magenta
        regular6 = mkDefault (toFootColor ansiColors.cyan); # cyan
        regular7 = mkDefault (toFootColor ansiColors.white); # white

        # Bright colors (8-15)
        bright0 = mkDefault (toFootColor ansiColors.bright-black); # bright black
        bright1 = mkDefault (toFootColor ansiColors.bright-red); # bright red
        bright2 = mkDefault (toFootColor ansiColors.bright-green); # bright green
        bright3 = mkDefault (toFootColor ansiColors.bright-yellow); # bright yellow
        bright4 = mkDefault (toFootColor ansiColors.bright-blue); # bright blue
        bright5 = mkDefault (toFootColor ansiColors.bright-magenta); # bright magenta
        bright6 = mkDefault (toFootColor ansiColors.bright-cyan); # bright cyan
        bright7 = mkDefault (toFootColor ansiColors.bright-white); # bright white
      };
    };
  };
}
