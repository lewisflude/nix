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
let
  inherit (lib) mkIf removePrefix;
  cfg = config.theming.signal.nixos;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Helper to get hex without # prefix (console.colors requires no #)
  hexRaw = color: removePrefix "#" color.hex;

  # ANSI color mapping using semantic bridge - matches terminal modules for consistency
  # console.colors expects an array of 16 hex colors (without #)
  ansiColors = [
    # Normal colors (0-7)
    (hexRaw (semantic.terminal "ansi-black" themeMode)) # 0: black
    (hexRaw (semantic.terminal "ansi-red" themeMode)) # 1: red
    (hexRaw (semantic.terminal "ansi-green" themeMode)) # 2: green
    (hexRaw (semantic.terminal "ansi-yellow" themeMode)) # 3: yellow
    (hexRaw (semantic.terminal "ansi-blue" themeMode)) # 4: blue
    (hexRaw (semantic.terminal "ansi-magenta" themeMode)) # 5: magenta
    (hexRaw (semantic.terminal "ansi-cyan" themeMode)) # 6: cyan
    (hexRaw (semantic.terminal "ansi-white" themeMode)) # 7: white

    # Bright colors (8-15)
    (hexRaw (semantic.terminal "ansi-bright-black" themeMode)) # 8: bright black
    (hexRaw (semantic.terminal "ansi-bright-red" themeMode)) # 9: bright red
    (hexRaw (semantic.terminal "ansi-bright-green" themeMode)) # 10: bright green
    (hexRaw (semantic.terminal "ansi-bright-yellow" themeMode)) # 11: bright yellow
    (hexRaw (semantic.terminal "ansi-bright-blue" themeMode)) # 12: bright blue
    (hexRaw (semantic.terminal "ansi-bright-magenta" themeMode)) # 13: bright magenta
    (hexRaw (semantic.terminal "ansi-bright-cyan" themeMode)) # 14: bright cyan
    (hexRaw (semantic.terminal "ansi-bright-white" themeMode)) # 15: bright white
  ];

  # Determine if console should be themed
  shouldTheme = cfg.enable && cfg.boot.console.enable;
in
{
  config = mkIf shouldTheme {
    # Apply Signal ANSI colors to virtual console (TTY)
    # These colors appear in:
    # - Virtual terminals (Ctrl+Alt+F1-F6)
    # - Emergency/recovery mode
    # - Boot messages (before display manager)
    console.colors = ansiColors;
  };
}
