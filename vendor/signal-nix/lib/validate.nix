# Signal Validation Library
# Provides validation functions for color values and module configurations
# Used to detect hardcoded colors and ensure all colors come from palette

{ lib }:

rec {
  # ============================================================================
  # Color Format Detection
  # ============================================================================

  # Regex patterns for color formats
  hexColorPattern = "#[0-9a-fA-F]{6}";
  hexColorPatternWithAlpha = "#[0-9a-fA-F]{8}";
  oklchPattern = "oklch\\([0-9.]+\\s+[0-9.]+\\s+[0-9.]+\\)";
  rgbPattern = "rgb\\([0-9]+,\\s*[0-9]+,\\s*[0-9]+\\)";
  rgbaPattern = "rgba\\([0-9]+,\\s*[0-9]+,\\s*[0-9]+,\\s*[0-9.]+\\)";

  # Check if a string is a hex color (#RRGGBB or #RRGGBBAA)
  # Returns: true if string matches hex color format
  isHexColor =
    str:
    (builtins.match "#[0-9a-fA-F]{6}" str != null) || (builtins.match "#[0-9a-fA-F]{8}" str != null);

  # Check if a string is an OKLCH color
  # Format: oklch(L C H) where L is 0-1, C is 0+, H is 0-360
  # Returns: true if string matches oklch format
  isOklchColor = str: builtins.match "oklch\\([0-9.]+[ ]+[0-9.]+[ ]+[0-9.]+\\)" str != null;

  # Check if a string is an RGB color
  # Format: rgb(R, G, B) where R,G,B are 0-255
  # Returns: true if string matches rgb format
  isRgbColor = str: builtins.match "rgb\\([0-9]+,[ ]*[0-9]+,[ ]*[0-9]+\\)" str != null;

  # Check if a string is an RGBA color
  # Format: rgba(R, G, B, A) where R,G,B are 0-255, A is 0-1
  # Returns: true if string matches rgba format
  isRgbaColor = str: builtins.match "rgba\\([0-9]+,[ ]*[0-9]+,[ ]*[0-9]+,[ ]*[0-9.]+\\)" str != null;

  # Check if a value is a hardcoded color (any recognized color format)
  # This is the main function to detect colors that should come from palette
  # Returns: true if value is a hardcoded color
  isHardcodedColor =
    value:
    let
      isString = builtins.isString value;
    in
    if !isString then
      false
    else
      (builtins.match "#[0-9a-fA-F]{6}" value != null)
      || (builtins.match "#[0-9a-fA-F]{8}" value != null)
      || (builtins.match "oklch\\([0-9.]+[ ]+[0-9.]+[ ]+[0-9.]+\\)" value != null)
      || (builtins.match "rgb\\([0-9]+,[ ]*[0-9]+,[ ]*[0-9]+\\)" value != null)
      || (builtins.match "rgba\\([0-9]+,[ ]*[0-9]+,[ ]*[0-9]+,[ ]*[0-9.]+\\)" value != null);

  # ============================================================================
  # File Content Scanning
  # ============================================================================

  # Scan file content for hardcoded colors
  # Returns: true if any hardcoded colors are found
  # Note: This scans the raw file content, not evaluated Nix
  # Filters out comment lines to avoid false positives from documentation
  findHardcodedColors =
    content:
    let
      # Split content into lines
      lines = lib.splitString "\n" content;

      # Filter out comment lines (lines starting with # after whitespace)
      # Also filter out lines that are part of multi-line strings in comments
      nonCommentLines = lib.filter (
        line:
        let
          trimmed = lib.removePrefix " " (lib.removePrefix "  " (lib.removePrefix "    " line));
          isComment = lib.hasPrefix "#" trimmed;
        in
        !isComment
      ) lines;

      # Rejoin filtered content
      filteredContent = lib.concatStringsSep "\n" nonCommentLines;

      # Check for hex colors
      hasHex = builtins.match ".*#[0-9a-fA-F]{6}.*" filteredContent != null;

      # Check for OKLCH colors
      hasOklch = builtins.match ".*oklch\\([^)]+\\).*" filteredContent != null;

      # Check for RGB colors
      hasRgb = builtins.match ".*rgb\\([^)]+\\).*" filteredContent != null;

      # Check for RGBA colors
      hasRgba = builtins.match ".*rgba\\([^)]+\\).*" filteredContent != null;
    in
    hasHex || hasOklch || hasRgb || hasRgba;

  # Scan file content and return list of found hardcoded colors
  # This is more detailed than findHardcodedColors
  # Returns: list of { type, value, lineNumber } for each found color
  extractHardcodedColors =
    content:
    let
      lines = lib.splitString "\n" content;

      # Check a single line for colors
      checkLine =
        lineNum: line:
        let
          # Simple regex-based extraction (not perfect but good enough)
          hexMatches = builtins.match ".*#([0-9a-fA-F]{6}).*" line;
          oklchMatches = builtins.match ".*(oklch\\([^)]+\\)).*" line;
        in
        lib.optionals (hexMatches != null) [
          {
            type = "hex";
            value = "#${builtins.head hexMatches}";
            lineNumber = lineNum;
          }
        ]
        ++ lib.optionals (oklchMatches != null) [
          {
            type = "oklch";
            value = builtins.head oklchMatches;
            lineNumber = lineNum;
          }
        ];

      # Check all lines
      allMatches = lib.concatMap (i: checkLine (i + 1) (builtins.elemAt lines i)) (
        lib.range 0 ((builtins.length lines) - 1)
      );
    in
    allMatches;

  # ============================================================================
  # Module Validation
  # ============================================================================

  # Validate that a module file doesn't contain hardcoded colors
  # Throws an error if hardcoded colors are found
  # Returns: the file path if validation passes
  validateModuleFile =
    filePath:
    let
      content = builtins.readFile filePath;
      hasColors = findHardcodedColors content;
    in
    if hasColors then
      throw ''
        Hardcoded colors found in module: ${filePath}

        All colors must come from the semantic bridge:
          semantic.core "background" mode
          semantic.terminal "ansi-red" mode
          semantic.status "error" mode

        See docs/QUICK_REFERENCE.md for available semantic colors.
      ''
    else
      filePath;

  # Validate multiple module files at once
  # Returns: list of file paths if all pass validation
  # Throws: error on first file that fails validation
  validateModuleFiles = filePaths: map validateModuleFile filePaths;

  # ============================================================================
  # Color Value Validation
  # ============================================================================

  # Validate that a color value is a valid color object from palette
  # A valid color object has: hex, hexRaw, rgb, l, c, h
  # Returns: true if valid color object
  isValidColorObject =
    color:
    (builtins.isAttrs color)
    && (color ? hex)
    && (color ? hexRaw)
    && (color ? rgb)
    && (color ? l)
    && (color ? c)
    && (color ? h)
    && (builtins.isString color.hex)
    && (lib.hasPrefix "#" color.hex)
    && (builtins.stringLength color.hex == 7);

  # Validate that a value is either:
  # 1. A valid color object from palette, OR
  # 2. A string that is NOT a hardcoded color (e.g., a variable reference)
  # Returns: true if valid
  isValidColorValue =
    value:
    if builtins.isAttrs value then
      isValidColorObject value
    else if builtins.isString value then
      !isHardcodedColor value
    else
      false;

  # ============================================================================
  # Semantic Reference Validation
  # ============================================================================

  # Validate that a semantic reference exists in the semantic bridge
  # This requires the semantic bridge to be passed in
  # Returns: true if reference exists
  isValidSemanticReference =
    semantic: category: name:
    (semantic.semanticBridge ? ${category}) && (semantic.semanticBridge.${category} ? ${name});

  # Get helpful error message for invalid semantic reference
  # Returns: string with suggestions
  getSemanticReferenceError =
    semantic: category: name:
    let
      availableCategories = builtins.attrNames semantic.semanticBridge;
      categoryExists = semantic.semanticBridge ? ${category};
      availableNames =
        if categoryExists then builtins.attrNames semantic.semanticBridge.${category} else [ ];
    in
    ''
      Invalid semantic reference: ${category}.${name}

      Available categories: ${lib.concatStringsSep ", " availableCategories}

      ${
        if categoryExists then
          "Available names in '${category}': ${lib.concatStringsSep ", " availableNames}"
        else
          "Category '${category}' does not exist."
      }

      See docs/QUICK_REFERENCE.md for all available semantic references.
    '';

  # ============================================================================
  # Batch Validation
  # ============================================================================

  # Validate a set of color values
  # Returns: { valid = true/false; errors = [...]; }
  validateColors =
    colors:
    let
      results = lib.mapAttrs (name: value: {
        inherit name value;
        valid = isValidColorValue value;
        isHardcoded = builtins.isString value && isHardcodedColor value;
      }) colors;

      errors = lib.filter (r: !r.valid) (builtins.attrValues results);
      hardcoded = lib.filter (r: r.isHardcoded) (builtins.attrValues results);
    in
    {
      valid = errors == [ ];
      inherit errors hardcoded;
      summary =
        if errors == [ ] then
          "✓ All colors valid"
        else
          "✗ ${toString (builtins.length errors)} invalid colors, ${toString (builtins.length hardcoded)} hardcoded";
    };

  # ============================================================================
  # Test Helpers
  # ============================================================================

  # Create a test that validates no hardcoded colors in a file
  # Returns: derivation that fails if hardcoded colors found
  mkNoHardcodedColorsTest =
    pkgs: name: filePath:
    pkgs.runCommand "test-no-hardcoded-colors-${name}" { } ''
      echo "Checking ${filePath} for hardcoded colors..."

      # Read file content
      content=$(cat ${filePath})

      # Check for hex colors
      if echo "$content" | grep -E '#[0-9a-fA-F]{6}' > /dev/null; then
        echo "ERROR: Found hex colors in ${filePath}"
        echo "$content" | grep -n -E '#[0-9a-fA-F]{6}'
        exit 1
      fi

      # Check for OKLCH colors
      if echo "$content" | grep -E 'oklch\([0-9]' > /dev/null; then
        echo "ERROR: Found OKLCH colors in ${filePath}"
        echo "$content" | grep -n -E 'oklch\([0-9]'
        exit 1
      fi

      # Check for RGB colors
      if echo "$content" | grep -E 'rgb\([0-9]' > /dev/null; then
        echo "ERROR: Found RGB colors in ${filePath}"
        echo "$content" | grep -n -E 'rgb\([0-9]'
        exit 1
      fi

      echo "✓ No hardcoded colors found in ${filePath}"
      touch $out
    '';
}
