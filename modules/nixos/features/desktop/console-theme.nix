{
  lib,
  config,
  ...
}:
let
  cfg = config.host.features.desktop;

  # Import the Signal palette
  signalPalette = import ../../../../modules/shared/features/theming/palette.nix { };

  # Determine mode (default to dark if signalTheme not configured)
  mode = if cfg.signalTheme.enable then cfg.signalTheme.mode else "dark";

  # Get the appropriate palette based on mode
  palette =
    if mode == "light" then
      {
        tonal = signalPalette.tonal.light;
        accent = signalPalette.accent.light;
        categorical = signalPalette.categorical.light;
      }
    else
      {
        tonal = signalPalette.tonal.dark;
        accent = signalPalette.accent.dark;
        categorical = signalPalette.categorical.dark;
      };

  # Extract hex values without # prefix for console.colors
  # Linux console expects colors in format: RRGGBB
  mkConsoleColor = color: color.hexRaw;

  # ANSI color mapping using Signal palette
  # Order: black, red, green, yellow, blue, magenta, cyan, white,
  #        bright-black, bright-red, bright-green, bright-yellow,
  #        bright-blue, bright-magenta, bright-cyan, bright-white
  ansiColors =
    if mode == "light" then
      [
        # Normal colors (darker for light mode)
        (mkConsoleColor palette.tonal.divider-Lc15) # 0: Black (divider)
        (mkConsoleColor palette.accent.Lc60-h040) # 1: Red
        (mkConsoleColor palette.accent.Lc60-h130) # 2: Green
        (mkConsoleColor palette.categorical.GA04) # 3: Yellow
        (mkConsoleColor palette.categorical.GA05) # 4: Blue
        (mkConsoleColor palette.categorical.GA03) # 5: Magenta
        (mkConsoleColor palette.categorical.GA07) # 6: Cyan
        (mkConsoleColor palette.tonal.text-Lc60) # 7: White (secondary text)

        # Bright colors (lighter for light mode)
        (mkConsoleColor palette.tonal.text-Lc45) # 8: Bright Black (tertiary text)
        (mkConsoleColor palette.accent.Lc75-h040) # 9: Bright Red
        (mkConsoleColor palette.accent.Lc75-h130) # 10: Bright Green
        (mkConsoleColor palette.categorical.GA06) # 11: Bright Yellow (orange)
        (mkConsoleColor palette.accent.Lc75-h240) # 12: Bright Blue
        (mkConsoleColor palette.accent.Lc75-h290) # 13: Bright Magenta (purple)
        (mkConsoleColor palette.accent.Lc75-h190) # 14: Bright Cyan
        (mkConsoleColor palette.tonal.text-Lc75) # 15: Bright White (primary text)
      ]
    else
      [
        # Normal colors (darker for dark mode)
        (mkConsoleColor palette.tonal.base-L015) # 0: Black (base background)
        (mkConsoleColor palette.accent.Lc60-h040) # 1: Red
        (mkConsoleColor palette.accent.Lc60-h130) # 2: Green
        (mkConsoleColor palette.categorical.GA04) # 3: Yellow
        (mkConsoleColor palette.categorical.GA05) # 4: Blue
        (mkConsoleColor palette.categorical.GA03) # 5: Magenta
        (mkConsoleColor palette.categorical.GA07) # 6: Cyan
        (mkConsoleColor palette.tonal.text-Lc60) # 7: White (secondary text)

        # Bright colors (brighter for dark mode)
        (mkConsoleColor palette.tonal.divider-Lc30) # 8: Bright Black (divider)
        (mkConsoleColor palette.accent.Lc75-h040) # 9: Bright Red
        (mkConsoleColor palette.accent.Lc75-h130) # 10: Bright Green
        (mkConsoleColor palette.categorical.GA06) # 11: Bright Yellow (orange)
        (mkConsoleColor palette.accent.Lc75-h240) # 12: Bright Blue
        (mkConsoleColor palette.accent.Lc75-h290) # 13: Bright Magenta (purple)
        (mkConsoleColor palette.accent.Lc75-h190) # 14: Bright Cyan
        (mkConsoleColor palette.tonal.text-Lc75) # 15: Bright White (primary text)
      ];
in
{
  config = lib.mkIf cfg.enable {
    # Apply Signal theme colors to Linux virtual console (TTY)
    console = {
      colors = ansiColors;

      # Use a clean, readable font (Terminus is a good monospace font for console)
      font = "ter-v22n";
      earlySetup = true;
    };
  };
}
