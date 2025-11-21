# Simplified Theme Library
# Provides essential theming functions without over-engineering
{
  lib,
  palette,
# nix-colorizer ? null,
}:
rec {
  # Get palette for specific mode (light or dark)
  getPalette = mode: paletteType: if mode == "light" then paletteType.light else paletteType.dark;

  # Generate semantic color mappings based on mode
  # These provide human-readable names for common UI elements
  getSemanticColors =
    mode:
    let
      tonal = getPalette mode palette.tonal;
      accent = getPalette mode palette.accent;
      categorical = getPalette mode palette.categorical;
    in
    {
      # Surface colors
      "surface-base" = if mode == "light" then tonal.base-L095 else tonal.base-L015;
      "surface-subtle" = tonal.surface-Lc05;
      "surface-emphasis" = tonal.surface-Lc10;

      # Dividers and borders
      "divider-primary" = tonal.divider-Lc15;
      "divider-secondary" = tonal.divider-Lc30;

      # Text colors
      "text-tertiary" = tonal.text-Lc45;
      "text-secondary" = tonal.text-Lc60;
      "text-primary" = tonal.text-Lc75;

      # Accent colors (semantic)
      "accent-primary" = accent.Lc75-h130; # Success/affirmative
      "accent-danger" = accent.Lc75-h040; # Error
      "accent-warning" = accent.Lc75-h090; # Warning/attention
      "accent-info" = accent.Lc75-h190; # Info
      "accent-focus" = accent.Lc75-h240; # Focus
      "accent-special" = accent.Lc75-h290; # Special

      # Syntax highlighting colors
      "syntax-keyword" = categorical.GA05; # Blue
      "syntax-function-def" = accent.Lc75-h090; # Ochre/Yellow
      "syntax-function-call" = categorical.GA02; # Green
      "syntax-string" = categorical.GA01; # Red-Orange
      "syntax-number" = categorical.GA03; # Magenta
      "syntax-type" = categorical.GA06; # Orange
      "syntax-variable" = tonal.text-Lc75; # Default text
      "syntax-error" = accent.Lc75-h040; # Red
      "syntax-special" = accent.Lc75-h130; # Primary (for TODO, FIXME)
      "syntax-comment" = tonal.text-Lc45; # Muted text
      "syntax-constant" = categorical.GA03; # Magenta

      # Terminal ANSI colors
      "ansi-black" = if mode == "light" then tonal.base-L095 else tonal.base-L015;
      "ansi-red" = categorical.GA01;
      "ansi-green" = categorical.GA02;
      "ansi-yellow" = categorical.GA04;
      "ansi-blue" = categorical.GA05;
      "ansi-magenta" = categorical.GA03;
      "ansi-cyan" = categorical.GA07;
      "ansi-white" = tonal.text-Lc75;
      "ansi-bright-black" = tonal.text-Lc45;
      "ansi-bright-white" = if mode == "light" then tonal.base-L100 else tonal.text-Lc75;

      # Transparent color (for UI elements needing transparency)
      "transparent" = {
        l = 0.0;
        c = 0.0;
        h = 0.0;
        hex = "#00000000";
        hexRaw = "00000000";
        rgb = {
          r = 0;
          g = 0;
          b = 0;
        };
      };
    };

  # Generate a complete theme object for a given mode
  # This is the main API for creating themes
  generateTheme =
    mode: _validationOptions:
    let
      tonal = getPalette mode palette.tonal;
      accent = getPalette mode palette.accent;
      categorical = getPalette mode palette.categorical;
      semantic = getSemanticColors mode;
    in
    {
      inherit mode;

      # Primary API: semantic color tokens
      colors = semantic;

      # Internal palette access (for advanced use cases)
      _internal = {
        inherit
          tonal
          accent
          categorical
          semantic
          ;
      };

      # Helper functions
      withAlpha =
        color: alpha:
        let
          clampedAlpha = lib.trivial.max 0.0 (lib.trivial.min 1.0 alpha);
          alphaInt = builtins.floor (clampedAlpha * 255.0);
          toHex =
            n:
            let
              hexDigits = "0123456789abcdef";
            in
            "${builtins.substring (n / 16) 1 hexDigits}${builtins.substring (lib.mod n 16) 1 hexDigits}";
        in
        "${color.hex}${toHex alphaInt}";

      # Format conversion utilities
      formats = rec {
        hex = color: color.hex;
        hexRaw = color: color.hexRaw;
        rgb = color: color.rgb;
        rgbString = color: "${toString color.rgb.r},${toString color.rgb.g},${toString color.rgb.b}";
        rgbNormalized = color: {
          r = color.rgb.r / 255.0;
          g = color.rgb.g / 255.0;
          b = color.rgb.b / 255.0;
        };
        rgbNormalizedString =
          color:
          let
            norm = rgbNormalized color;
          in
          "${toString norm.r},${toString norm.g},${toString norm.b}";
        # BGR format for mpv and similar tools
        bgrHex =
          color:
          let
            toHex =
              n:
              let
                hexDigits = "0123456789abcdef";
              in
              "${builtins.substring (n / 16) 1 hexDigits}${builtins.substring (lib.mod n 16) 1 hexDigits}";
          in
          "#${toHex color.rgb.b}${toHex color.rgb.g}${toHex color.rgb.r}";
        bgrHexRaw = color: lib.removePrefix "#" (bgrHex color);
        oklch = color: "oklch(${toString color.l} ${toString color.c} ${toString color.h})";
      };
    };

  # Get all ANSI terminal colors as a list
  getAnsiColorsList =
    mode:
    let
      semantic = getSemanticColors mode;
    in
    [
      semantic."ansi-black".hex
      semantic."ansi-red".hex
      semantic."ansi-green".hex
      semantic."ansi-yellow".hex
      semantic."ansi-blue".hex
      semantic."ansi-magenta".hex
      semantic."ansi-cyan".hex
      semantic."ansi-white".hex
      semantic."ansi-bright-black".hex
      semantic."ansi-red".hex
      semantic."ansi-green".hex
      semantic."ansi-yellow".hex
      semantic."ansi-blue".hex
      semantic."ansi-magenta".hex
      semantic."ansi-cyan".hex
      semantic."ansi-bright-white".hex
    ];
}
