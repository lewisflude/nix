{ lib, palette }:
let
  inherit (lib) optionalAttrs;
in
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
      "syntax-function-def" = accent.Lc75-h090; # Warning color (Ochre/Yellow)
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
    };

  # Generate a complete theme object for a given mode
  generateTheme =
    mode:
    let
      tonal = getPalette mode palette.tonal;
      accent = getPalette mode palette.accent;
      categorical = getPalette mode palette.categorical;
      semantic = getSemanticColors mode;
    in
    {
      inherit
        mode
        tonal
        accent
        categorical
        semantic
        ;

      # Convenience accessors
      colors = semantic;

      # Helper functions
      withAlpha =
        color: alpha:
        let
          # Convert alpha (0.0-1.0) to hex (00-FF)
          alphaHex =
            let
              alphaInt = builtins.floor (alpha * 255);
              toHexDigit =
                n:
                if n < 10 then
                  toString n
                else if n == 10 then
                  "a"
                else if n == 11 then
                  "b"
                else if n == 12 then
                  "c"
                else if n == 13 then
                  "d"
                else if n == 14 then
                  "e"
                else
                  "f";
            in
            toHexDigit (alphaInt / 16) + toHexDigit (lib.mod alphaInt 16);
        in
        "${color.hex}${alphaHex}";

      # Format color as CSS oklch() string
      toOklch = color: "oklch(${toString color.l} ${toString color.c} ${toString color.h})";

      # Format color as CSS rgb() string
      toRgb = color: "rgb(${toString color.rgb.r}, ${toString color.rgb.g}, ${toString color.rgb.b})";
    };

  # Utility: Convert hex to RGB values
  hexToRgb =
    hex:
    let
      cleanHex = if builtins.substring 0 1 hex == "#" then builtins.substring 1 6 hex else hex;
    in
    {
      r = lib.toInt "0x${builtins.substring 0 2 cleanHex}";
      g = lib.toInt "0x${builtins.substring 2 2 cleanHex}";
      b = lib.toInt "0x${builtins.substring 4 2 cleanHex}";
    };

  # Utility: Lighten or darken a color by a percentage
  # Note: This is approximate and works by adjusting the lightness
  adjustLightness =
    color: percentage:
    let
      newL = lib.trivial.max 0.0 (lib.trivial.min 1.0 (color.l * (1.0 + percentage)));
    in
    color // { l = newL; };

  # Get all ANSI terminal colors as a list (useful for terminal configs)
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
      semantic."ansi-red".hex # bright red (reuse)
      semantic."ansi-green".hex # bright green (reuse)
      semantic."ansi-yellow".hex # bright yellow (reuse)
      semantic."ansi-blue".hex # bright blue (reuse)
      semantic."ansi-magenta".hex # bright magenta (reuse)
      semantic."ansi-cyan".hex # bright cyan (reuse)
      semantic."ansi-bright-white".hex
    ];
}
