{
  lib,
  palette,
  nix-colorizer ? null,
  validationLib ? null,
}:
let
  inherit (lib) optionalAttrs;

  # Mathematical constants
  PI = 3.141592653589793;
  DEGREES_TO_RADIANS = PI / 180.0;
  RADIANS_TO_DEGREES = 180.0 / PI;

  # Helper to convert our color format to nix-colorizer oklch format
  # Our format: { l, c, h } where h is in degrees (0-360)
  # nix-colorizer format: { L, C, h, a } where h is in radians
  toColorizerOklch = color: {
    L = color.l;
    C = color.c;
    h = color.h * DEGREES_TO_RADIANS;
    a = 1.0;
  };

  # Helper to convert nix-colorizer oklch format to our color format
  # Only available when nix-colorizer is provided
  fromColorizerOklch =
    if nix-colorizer != null then
      (oklch: {
        l = oklch.L;
        c = oklch.C;
        h = oklch.h * RADIANS_TO_DEGREES;
        hex = nix-colorizer.oklch.to.hex oklch;
        hexRaw = lib.removePrefix "#" (nix-colorizer.oklch.to.hex oklch);
        rgb =
          let
            MAX_RGB = 255.0;
            srgb = nix-colorizer.oklch.to.srgb oklch;
          in
          {
            r = builtins.floor (srgb.r * MAX_RGB);
            g = builtins.floor (srgb.g * MAX_RGB);
            b = builtins.floor (srgb.b * MAX_RGB);
          };
      })
    else
      (oklch: throw "nix-colorizer is required for fromColorizerOklch");
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
  # Validates mode and returns a theme object with all color formats and utilities
  #
  # IMPORTANT: This function enforces semantic token abstraction.
  # Developers should ONLY use theme.colors (semantic tokens).
  # Direct access to tonal, accent, and categorical palettes is discouraged
  # and may be removed in future versions.
  #
  # Optional validation can be enabled via validationOptions:
  #   { enable = true; strictMode = false; level = "AA"; validationLevel = "standard"; useAPCA = false; }
  # If validationOptions is null or not an attribute set, validation is disabled (backward compatible)
  #
  # Backward compatibility: Can be called as generateTheme mode or generateTheme mode validationOptions
  generateTheme =
    mode: validationOptions:
    let
      # Validate mode
      validModes = [
        "light"
        "dark"
      ];
      _ =
        if !builtins.elem mode validModes then
          throw "Invalid theme mode: ${mode}. Must be one of: ${lib.concatStringsSep ", " validModes}"
        else
          null;

      tonal = getPalette mode palette.tonal;
      accent = getPalette mode palette.accent;
      categorical = getPalette mode palette.categorical;
      semantic = getSemanticColors mode;

      # Default validation options (disabled)
      # Check if validationOptions is a valid attribute set, otherwise default to disabled
      defaultValidationOptions = {
        enable = false;
        strictMode = false;
        level = "AA";
        validationLevel = "standard";
        useAPCA = false;
      };
      # Check if validationOptions is an attribute set (has enable key or is empty set)
      isValidOptions = validationOptions != null && builtins.isAttrs validationOptions;
      opts = if isValidOptions then validationOptions else defaultValidationOptions;

      # Build theme object
      theme = {
        inherit mode;

        # PRIMARY API: Use semantic tokens only
        # This is the ONLY way developers should access colors
        # Semantic tokens automatically adapt to light/dark mode and maintain accessibility
        colors = semantic;

        # DEPRECATED: Legacy access for backward compatibility
        # ?? WARNING: Use theme.colors instead. This will be removed in a future version.
        semantic = semantic;

        # DEPRECATED: Direct palette access
        # ?? WARNING: Direct access to tonal, accent, and categorical palettes is discouraged.
        # Use theme.colors (semantic tokens) instead.
        # These may be removed in future versions to enforce strict semantic token abstraction.
        #
        # If you need these for internal theme generation, consider using a separate internal API.
        _internal = {
          inherit
            tonal
            accent
            categorical
            semantic
            ;
        };

        # Helper functions
        # Add alpha channel to a color
        # Input: color object, alpha value (0.0-1.0)
        # Output: hex string with alpha channel (e.g., "#a3b5c7ff")
        withAlpha =
          color: alpha:
          let
            MAX_ALPHA = 255;
            # Validate and clamp alpha
            clampedAlpha = lib.trivial.max 0.0 (lib.trivial.min 1.0 alpha);
            alphaInt = builtins.floor (clampedAlpha * MAX_ALPHA);
            # Convert integer (0-255) to two hex digits
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
            alphaHex = toHexDigit (alphaInt / 16) + toHexDigit (lib.mod alphaInt 16);
          in
          "${color.hex}${alphaHex}";

        # Format color as CSS oklch() string
        toOklch = color: "oklch(${toString color.l} ${toString color.c} ${toString color.h})";

        # Format color as CSS rgb() string
        toRgb = color: "rgb(${toString color.rgb.r}, ${toString color.rgb.g}, ${toString color.rgb.b})";

        # Color manipulation functions using nix-colorizer (if available)
        # These provide proper OKLCH-based color manipulation
        manipulate =
          if nix-colorizer != null then
            {
              # Lighten a color (value is added to lightness)
              lighten =
                color: value: fromColorizerOklch (nix-colorizer.oklch.lighten (toColorizerOklch color) value);

              # Darken a color (value is subtracted from lightness)
              darken =
                color: value: fromColorizerOklch (nix-colorizer.oklch.darken (toColorizerOklch color) value);

              # Blend two colors (mod is 0.0-1.0, 0.0 = first color, 1.0 = second color)
              blend =
                color1: color2: mod:
                fromColorizerOklch (
                  nix-colorizer.oklch.blend (toColorizerOklch color1) (toColorizerOklch color2) mod
                );

              # Generate gradient between two colors (steps = number of intermediate colors)
              gradient =
                color1: color2: steps:
                map fromColorizerOklch (
                  nix-colorizer.oklch.gradient (toColorizerOklch color1) (toColorizerOklch color2) steps
                );

              # Generate shades (from color to black)
              shades =
                color: steps: map fromColorizerOklch (nix-colorizer.oklch.shades (toColorizerOklch color) steps);

              # Generate tints (from color to white)
              tints =
                color: steps: map fromColorizerOklch (nix-colorizer.oklch.tints (toColorizerOklch color) steps);

              # Generate tones (from color to grey by decreasing chroma)
              tones =
                color: steps: map fromColorizerOklch (nix-colorizer.oklch.tones (toColorizerOklch color) steps);

              # Generate polygon colors (evenly distributed on hue wheel)
              polygon =
                color: count: map fromColorizerOklch (nix-colorizer.oklch.polygon (toColorizerOklch color) count);

              # Get complementary color
              complementary =
                color: fromColorizerOklch (nix-colorizer.oklch.complementary (toColorizerOklch color));

              # Get analogous colors (two colors 30? on either side)
              analogous = color: map fromColorizerOklch (nix-colorizer.oklch.analogous (toColorizerOklch color));

              # Get split-complementary colors
              splitComplementary =
                color: map fromColorizerOklch (nix-colorizer.oklch.splitComplementary (toColorizerOklch color));
            }
          else
            {
              # Fallback to simple implementations when nix-colorizer is not available
              # Note: These use approximate methods. For proper OKLCH-based manipulation,
              # ensure nix-colorizer is available via _module.args.nix-colorizer
              lighten = color: value: adjustLightness color value;
              darken = color: value: adjustLightness color (-value);
              blend =
                color1: color2: mod:
                throw "nix-colorizer is required for blend function. Add nix-colorizer to flake inputs and specialArgs.";
              gradient =
                color1: color2: steps:
                throw "nix-colorizer is required for gradient function. Add nix-colorizer to flake inputs and specialArgs.";
              shades =
                color: steps:
                throw "nix-colorizer is required for shades function. Add nix-colorizer to flake inputs and specialArgs.";
              tints =
                color: steps:
                throw "nix-colorizer is required for tints function. Add nix-colorizer to flake inputs and specialArgs.";
              tones =
                color: steps:
                throw "nix-colorizer is required for tones function. Add nix-colorizer to flake inputs and specialArgs.";
              polygon =
                color: count:
                throw "nix-colorizer is required for polygon function. Add nix-colorizer to flake inputs and specialArgs.";
              complementary =
                color:
                throw "nix-colorizer is required for complementary function. Add nix-colorizer to flake inputs and specialArgs.";
              analogous =
                color:
                throw "nix-colorizer is required for analogous function. Add nix-colorizer to flake inputs and specialArgs.";
              splitComplementary =
                color:
                throw "nix-colorizer is required for splitComplementary function. Add nix-colorizer to flake inputs and specialArgs.";
            };

        # Format conversion utilities for different applications
        formats = rec {
          # Hex with # prefix (for CSS, most configs)
          hex = color: color.hex;
          # Hex without # prefix (for fzf, some tools)
          hexRaw = color: color.hexRaw;
          # RGB tuple (r, g, b) as integers 0-255
          rgb = color: color.rgb;
          # RGB string "r,g,b" (for MangoHud, etc.)
          rgbString = color: "${toString color.rgb.r},${toString color.rgb.g},${toString color.rgb.b}";
          # RGB normalized 0.0-1.0 (for some tools)
          rgbNormalized =
            color:
            let
              MAX_RGB = 255.0;
            in
            {
              r = color.rgb.r / MAX_RGB;
              g = color.rgb.g / MAX_RGB;
              b = color.rgb.b / MAX_RGB;
            };
          # RGB normalized string "r,g,b" (for MangoHud with normalized values)
          rgbNormalizedString =
            color:
            let
              normalized = rgbNormalized color;
            in
            "${toString normalized.r},${toString normalized.g},${toString normalized.b}";
          # OKLCH string
          oklch = color: "oklch(${toString color.l} ${toString color.c} ${toString color.h})";
        };

        # Validation (if enabled and validationLib is available)
        _validation =
          if validationLib != null && opts.enable then
            let
              validationLevel = opts.validationLevel or "standard";
              level = opts.level or "AA";
              useAPCA = opts.useAPCA or false;
              strict = opts.strictMode or false;

              # Run validation based on level
              validationResult =
                if validationLevel == "basic" then
                  validationLib.validateThemeCompleteness theme
                else if validationLevel == "standard" then
                  let
                    completeness = validationLib.validateThemeCompleteness theme;
                    accessibility = validationLib.validateAccessibility {
                      inherit theme level useAPCA;
                    };
                  in
                  validationLib.combineResults [
                    completeness
                    accessibility
                  ]
                else
                  # strict level: full validation
                  validationLib.validateTheme {
                    inherit
                      theme
                      level
                      useAPCA
                      strict
                      ;
                    textSize = "normal";
                  };
            in
            {
              result = validationResult;
              report = validationLib.generateReport validationResult;
              json = validationLib.generateJSONReport validationResult;
              summary = validationLib.generateSummary validationResult;
            }
          else
            null;
      };

      # Apply validation if enabled
      finalTheme =
        if validationLib != null && opts.enable then
          let
            validation = theme._validation;
            strict = opts.strictMode or false;
          in
          if strict && !validation.result.passed then
            throw "Theme validation failed (strict mode enabled):\n${validation.report}"
          else
            theme
        else
          theme;
    in
    finalTheme;

  # Helper to convert a single hex digit (0-9, a-f, A-F) to integer (0-15)
  hexDigitToInt =
    c:
    if c == "0" then
      0
    else if c == "1" then
      1
    else if c == "2" then
      2
    else if c == "3" then
      3
    else if c == "4" then
      4
    else if c == "5" then
      5
    else if c == "6" then
      6
    else if c == "7" then
      7
    else if c == "8" then
      8
    else if c == "9" then
      9
    else if c == "a" || c == "A" then
      10
    else if c == "b" || c == "B" then
      11
    else if c == "c" || c == "C" then
      12
    else if c == "d" || c == "D" then
      13
    else if c == "e" || c == "E" then
      14
    else if c == "f" || c == "F" then
      15
    else
      throw "Invalid hex digit: ${c}";

  # Helper to convert a hex pair (e.g., "a3") to integer (0-255)
  # Input: two-character hex string (e.g., "a3", "FF")
  # Output: integer value
  hexPairToInt =
    pair:
    (hexDigitToInt (builtins.substring 0 1 pair)) * 16 + (hexDigitToInt (builtins.substring 1 1 pair));

  # Utility: Convert hex string to RGB values
  # Input: hex string with or without # prefix (e.g., "#a3b5c7" or "a3b5c7")
  # Output: { r, g, b } where each value is 0-255
  hexToRgb =
    hex:
    let
      cleanHex = if builtins.substring 0 1 hex == "#" then builtins.substring 1 6 hex else hex;
      hexLen = builtins.stringLength cleanHex;
      _ =
        if hexLen != 6 then
          throw "Invalid hex color: ${hex} (expected 6 hex digits, got ${toString hexLen})"
        else
          null;
    in
    {
      r = hexPairToInt (builtins.substring 0 2 cleanHex);
      g = hexPairToInt (builtins.substring 2 2 cleanHex);
      b = hexPairToInt (builtins.substring 4 2 cleanHex);
    };

  # Utility: Lighten or darken a color by a percentage
  # Note: This is approximate and works by adjusting the lightness
  # Deprecated: Use theme.manipulate.lighten/darken for proper OKLCH-based manipulation
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
