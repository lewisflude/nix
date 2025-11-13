{
  lib,
  palette,
  nix-colorizer ? null,
  validationLib ? null,
}:
let

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
      (_oklch: throw "nix-colorizer is required for fromColorizerOklch");
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

      # Transparent colors (for UI elements that need full transparency)
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
      # Semantic aliases for transparent
      "surface-transparent" = {
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
      "border-transparent" = {
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

        # Internal palette access (for advanced use cases only)
        # Direct access to tonal, accent, and categorical palettes is discouraged.
        # Use theme.colors (semantic tokens) instead for all application theming.
        # Internal access is provided for theme generation and advanced transformations only.
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
                _color1: _color2: _mod:
                throw "nix-colorizer is required for blend function. Add nix-colorizer to flake inputs and specialArgs.";
              gradient =
                _color1: _color2: _steps:
                throw "nix-colorizer is required for gradient function. Add nix-colorizer to flake inputs and specialArgs.";
              shades =
                _color: _steps:
                throw "nix-colorizer is required for shades function. Add nix-colorizer to flake inputs and specialArgs.";
              tints =
                _color: _steps:
                throw "nix-colorizer is required for tints function. Add nix-colorizer to flake inputs and specialArgs.";
              tones =
                _color: _steps:
                throw "nix-colorizer is required for tones function. Add nix-colorizer to flake inputs and specialArgs.";
              polygon =
                _color: _count:
                throw "nix-colorizer is required for polygon function. Add nix-colorizer to flake inputs and specialArgs.";
              complementary =
                _color:
                throw "nix-colorizer is required for complementary function. Add nix-colorizer to flake inputs and specialArgs.";
              analogous =
                _color:
                throw "nix-colorizer is required for analogous function. Add nix-colorizer to flake inputs and specialArgs.";
              splitComplementary =
                _color:
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
          # BGR hex string #BBGGRR (for mpv script-opts, which uses Blue-Green-Red order)
          # Converts RGB hex #RRGGBB to BGR hex #BBGGRR
          # Example: #cdd6f4 (RGB) -> #f4d6cd (BGR)
          bgrHex =
            color:
            let
              inherit (color) rgb;
              # Convert integer 0-255 to 2-digit hex string
              intToHex =
                n:
                let
                  hexDigits = "0123456789abcdef";
                  high = builtins.floor (n / 16);
                  low = n - (high * 16);
                in
                "${builtins.substring high 1 hexDigits}${builtins.substring low 1 hexDigits}";
            in
            "#${intToHex rgb.b}${intToHex rgb.g}${intToHex rgb.r}";
          # BGR hex without # prefix (for mpv script-opts)
          bgrHexRaw = color: lib.removePrefix "#" (bgrHex color);
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

  # ============================================================================
  # Brand Color Transformation Utilities
  # ============================================================================
  # Utilities for converting, validating, and transforming brand colors

  # Convert hex color to OKLCH format
  # Input: hex string (e.g., "#ff6b35" or "ff6b35")
  # Output: { l, c, h, hex, hexRaw, rgb } color object
  # Requires nix-colorizer for accurate conversion
  hexToOklch =
    hex:
    if nix-colorizer != null then
      let
        rgb = hexToRgb hex;
        # Convert RGB to sRGB (0.0-1.0)
        srgb = {
          r = rgb.r / 255.0;
          g = rgb.g / 255.0;
          b = rgb.b / 255.0;
        };
        # Convert sRGB to OKLCH using nix-colorizer
        oklch = nix-colorizer.srgb.to.oklch srgb;
      in
      fromColorizerOklch oklch
    else
      throw "nix-colorizer is required for hexToOklch. Add nix-colorizer to flake inputs and specialArgs.";

  # Validate brand color meets accessibility requirements
  # Checks contrast against common background colors
  # Returns: { passed, errors, warnings, suggestions }
  validateBrandColorAccessibility =
    {
      brandColor,
      validationLib ? null,
      level ? "AA",
      backgrounds ? [ ],
    }:
    if validationLib == null then
      {
        passed = true;
        errors = [ ];
        warnings = [ "Validation library not available. Cannot validate brand color accessibility." ];
        suggestions = [ ];
      }
    else
      let
        # Default backgrounds to check against (if not provided)
        defaultBackgrounds =
          if backgrounds == [ ] then
            [
              {
                name = "surface-base-light";
                color = {
                  rgb = {
                    r = 255;
                    g = 255;
                    b = 255;
                  };
                };
              }
              {
                name = "surface-base-dark";
                color = {
                  rgb = {
                    r = 30;
                    g = 31;
                    b = 38;
                  };
                };
              }
              {
                name = "text-primary-light";
                color = {
                  rgb = {
                    r = 30;
                    g = 31;
                    b = 38;
                  };
                };
              }
              {
                name = "text-primary-dark";
                color = {
                  rgb = {
                    r = 192;
                    g = 195;
                    b = 209;
                  };
                };
              }
            ]
          else
            backgrounds;

        # Check contrast for each background
        contrastChecks = map (
          bg:
          let
            result = validationLib.validateContrast {
              textColor = brandColor;
              backgroundColor = bg.color;
              inherit level;
              textSize = "normal";
            };
          in
          {
            background = bg.name;
            inherit result;
          }
        ) defaultBackgrounds;

        # Collect all errors and warnings
        allErrors = lib.concatLists (map (check: check.result.errors) contrastChecks);
        allWarnings = lib.concatLists (map (check: check.result.warnings) contrastChecks);
        passed = lib.all (check: check.result.passed) contrastChecks;

        # Generate suggestions for improving accessibility
        suggestions =
          if !passed then
            [
              "Consider increasing lightness for better contrast on dark backgrounds"
              "Consider adjusting chroma to improve visibility"
              "Use brand color for decorative elements only if contrast is insufficient"
            ]
          else
            [ ];
      in
      {
        inherit passed suggestions;
        errors = allErrors;
        warnings = allWarnings;
      };

  # Suggest accessible alternatives for a brand color
  # Returns a list of color suggestions with improved accessibility
  suggestAccessibleAlternatives =
    {
      brandColor,
      nSteps ? 3,
    }:
    if nix-colorizer == null then
      [ ]
    else
      let
        # Try lightening the color
        lightenSteps = lib.genList (
          i:
          let
            amount = (i + 1) * 0.05; # 0.05, 0.10, 0.15
            adjusted = fromColorizerOklch (nix-colorizer.oklch.lighten (toColorizerOklch brandColor) amount);
          in
          {
            method = "lighten";
            inherit amount;
            color = adjusted;
          }
        ) nSteps;

        # Try increasing chroma
        chromaSteps = lib.genList (
          i:
          let
            oklch = toColorizerOklch brandColor;
            amount = (i + 1) * 0.05; # 0.05, 0.10, 0.15
            adjusted = fromColorizerOklch (oklch // { C = oklch.C + amount; });
          in
          {
            method = "increase-chroma";
            inherit amount;
            color = adjusted;
          }
        ) nSteps;
      in
      lightenSteps ++ chromaSteps;

  # Apply brand colors to theme based on governance policy
  # This integrates brand colors into the theme according to the policy
  # Supports both single brand colors and multiple brand layers
  applyBrandColors =
    {
      theme,
      brandGovernance,
      validationLib ? null,
    }:
    let
      policy = brandGovernance.policy or "functional-override";
      decorativeBrandColors = brandGovernance.decorativeBrandColors or { };
      brandColors = brandGovernance.brandColors or { };
      brandLayers = brandGovernance.brandLayers or { };

      # Convert decorative brand colors (hex strings) to OKLCH if needed
      decorativeOklch =
        if decorativeBrandColors != { } && nix-colorizer != null then
          lib.mapAttrs (_: hexToOklch) decorativeBrandColors
        else
          { };

      # Process multiple brand layers
      # Sort layers by priority (ascending, so lower priority is applied first)
      sortedLayers = lib.sort (a: b: (a.value.priority or 0) < (b.value.priority or 0)) (
        lib.mapAttrsToList (name: value: { inherit name value; }) brandLayers
      );

      # Merge all decorative colors from layers (in priority order)
      allDecorativeFromLayers = lib.foldl (
        acc: layer:
        let
          layerDecorative = layer.value.decorative or { };
          # Convert hex to OKLCH if nix-colorizer is available
          layerDecorativeOklch =
            if layerDecorative != { } && nix-colorizer != null then
              lib.mapAttrs (_: hexToOklch) layerDecorative
            else
              { };
        in
        acc // layerDecorativeOklch
      ) { } sortedLayers;

      # Merge all functional colors from layers (in priority order)
      allFunctionalFromLayers = lib.foldl (
        acc: layer:
        let
          layerFunctional = layer.value.functional or { };
        in
        acc // layerFunctional
      ) { } sortedLayers;

      # Combine single brand colors with layer colors (layers take precedence)
      allDecorative = decorativeOklch // allDecorativeFromLayers;
      allFunctional = brandColors // allFunctionalFromLayers;

      # Validate brand colors if policy is "integrated"
      brandColorValidation =
        if policy == "integrated" && validationLib != null then
          lib.mapAttrs (
            _name: color:
            validateBrandColorAccessibility {
              brandColor = color;
              inherit validationLib;
              level = "AA";
            }
          ) allFunctional
        else
          { };

      # Check if any brand colors fail validation
      validationFailed = lib.any (result: !result.passed) (lib.attrValues brandColorValidation);

      # Apply brand colors based on policy
      appliedTheme =
        if policy == "functional-override" then
          # Brand colors are decorative only, add them to theme but don't override semantic colors
          theme
          // {
            _brand = {
              decorative = allDecorative;
              layers = brandLayers;
            };
          }
        else if policy == "separate-layer" then
          # Brand colors exist as separate layer
          theme
          // {
            _brand = {
              decorative = allDecorative;
              functional = { }; # Functional colors unchanged
              layers = brandLayers;
            };
          }
        else if policy == "integrated" then
          # Brand colors replace functional colors (if validation passes)
          if validationFailed then
            throw "Brand color validation failed. Cannot integrate brand colors that don't meet accessibility requirements."
          else
            theme
            // {
              colors = theme.colors // allFunctional;
              _brand = {
                integrated = allFunctional;
                decorative = allDecorative;
                validation = brandColorValidation;
                layers = brandLayers;
              };
            }
        else
          throw "Unknown brand governance policy: ${policy}";
    in
    appliedTheme;

  # ============================================================================
  # Theme Factory Pattern
  # ============================================================================
  # Provides composable theme creation with support for overrides, extensions,
  # variants, validation hooks, and caching.

  # Create a theme factory that provides composable theme creation
  # This is the main entry point for advanced theme customization
  #
  # Usage:
  #   factory = createThemeFactory {
  #     inherit palette nix-colorizer validationLib;
  #   };
  #   theme = factory.create {
  #     mode = "dark";
  #     overrides = { "accent-primary" = customColor; };
  #     variant = "high-contrast";
  #   };
  createThemeFactory =
    {
      palette,
      nix-colorizer ? null,
      validationLib ? null,
    }:
    let
      # Generate cache key from theme configuration
      # In Nix, actual caching is handled by the store, but we can create
      # deterministic keys for memoization within the same evaluation

      # Apply color overrides to semantic colors
      # Merges user-provided overrides into the base semantic color mapping
      applyOverrides = baseSemantic: overrides: baseSemantic // overrides;

      # Apply variant transformations to semantic colors
      # Variants modify the base theme for accessibility or preference
      applyVariant =
        semantic: variant:
        if variant == null || variant == "default" then
          semantic
        else if variant == "high-contrast" then
          # Increase contrast by adjusting lightness differences
          # This is a simplified implementation - can be enhanced
          lib.mapAttrs (
            name: color:
            if lib.hasPrefix "text-" name then
              # Lighten text colors for better contrast
              if nix-colorizer != null then
                fromColorizerOklch (nix-colorizer.oklch.lighten (toColorizerOklch color) 0.1)
              else
                adjustLightness color 0.1
            else if lib.hasPrefix "surface-" name then
              # Darken surfaces for better contrast
              if nix-colorizer != null then
                fromColorizerOklch (nix-colorizer.oklch.darken (toColorizerOklch color) 0.05)
              else
                adjustLightness color (-0.05)
            else
              color
          ) semantic
        else if variant == "reduced-motion" then
          # Reduce saturation for less visual motion
          if nix-colorizer != null then
            lib.mapAttrs (
              _name: color:
              let
                oklch = toColorizerOklch color;
                reducedChroma = oklch.C * 0.7; # Reduce chroma by 30%
                adjusted = oklch // {
                  C = reducedChroma;
                };
              in
              fromColorizerOklch adjusted
            ) semantic
          else
            semantic # Cannot reduce motion without nix-colorizer
        else if variant == "color-blind-friendly" then
          # Adjust hues to be more distinguishable for color-blind users
          # This is a simplified implementation
          semantic # Placeholder - would need specific transformations
        else
          throw "Unknown variant: ${variant}. Supported variants: high-contrast, reduced-motion, color-blind-friendly";

      # Extension point: pre-generation hook
      # Allows transformation of configuration before theme generation
      runPreHooks =
        config: hooks: if hooks == [ ] then config else lib.foldl (acc: hook: hook acc) config hooks;

      # Extension point: post-generation hook
      # Allows transformation of theme after generation
      runPostHooks =
        theme: hooks: if hooks == [ ] then theme else lib.foldl (acc: hook: hook acc) theme hooks;
    in
    {
      # Create a theme with the factory
      # This is the main factory method that orchestrates theme creation
      create =
        {
          mode,
          overrides ? { },
          variant ? null,
          validationOptions ? null,
          brandGovernance ? null,
          preHooks ? [ ],
          postHooks ? [ ],
        }:
        let
          # Run pre-generation hooks
          processedConfig = runPreHooks {
            inherit
              mode
              overrides
              variant
              brandGovernance
              ;
          } preHooks;

          # Generate cache key for this configuration
          # Note: In Nix, actual caching is handled by the store based on function inputs
          # This key is useful for debugging and potential future memoization

          # Generate base theme (validation is integrated via validationOptions)
          baseTheme = generateTheme mode validationOptions;

          # Apply overrides to semantic colors
          overriddenSemantic = applyOverrides baseTheme.colors processedConfig.overrides;

          # Apply variant transformations
          variantSemantic = applyVariant overriddenSemantic processedConfig.variant;

          # Create theme with overridden colors
          themeWithOverrides = baseTheme // {
            colors = variantSemantic;
            _internal = baseTheme._internal // {
              semantic = variantSemantic;
            };
          };

          # Apply brand colors if provided
          themeWithBrand =
            if processedConfig.brandGovernance != null then
              applyBrandColors {
                inherit themeWithOverrides validationLib;
                inherit (processedConfig) brandGovernance;
              }
            else
              themeWithOverrides;

          # Run post-generation hooks (can include additional validation)
          themeAfterHooks = runPostHooks themeWithBrand postHooks;

          # Post-generation validation hook (if validationLib is available and enabled)
          # This allows validation after all transformations are applied
          finalTheme =
            if validationLib != null && validationOptions != null && validationOptions.enable then
              let
                # Run additional validation on the final theme
                postValidation = validationLib.validateTheme {
                  theme = themeAfterHooks;
                  level = validationOptions.level or "AA";
                  useAPCA = validationOptions.useAPCA or false;
                  strict = validationOptions.strictMode or false;
                  textSize = "normal";
                };

                # If strict mode and validation failed, throw error
                strict = validationOptions.strictMode or false;
              in
              if strict && !postValidation.passed then
                throw "Post-generation theme validation failed (strict mode):\n${validationLib.generateReport postValidation}"
              else
                # Add validation results to theme metadata
                themeAfterHooks
                // {
                  _validation = {
                    postGeneration = postValidation;
                    report = validationLib.generateReport postValidation;
                  };
                }
            else
              themeAfterHooks;
        in
        finalTheme;

      # Create a factory with default overrides applied to all themes
      withDefaults = defaultOverrides: {
        create =
          config:
          createThemeFactory
            {
              inherit palette nix-colorizer validationLib;
            }
            .create
            (
              config
              // {
                overrides = defaultOverrides // (config.overrides or { });
              }
            );
      };

      # Create a factory with a specific variant applied to all themes
      withVariant = variant: {
        create =
          config:
          createThemeFactory
            {
              inherit palette nix-colorizer validationLib;
            }
            .create
            (
              config
              // {
                variant = config.variant or variant;
              }
            );
      };
    };
}
