{ lib }:
let
  inherit (lib) concatStringsSep;

  # Validation result type
  # This represents the outcome of a validation check
  validationResult = {
    passed = true; # Whether validation passed
    errors = [ ]; # List of error messages
    warnings = [ ]; # List of warning messages
  };

  # Create a passed validation result
  mkPassed =
    {
      warnings ? [ ],
    }:
    {
      passed = true;
      errors = [ ];
      inherit warnings;
    };

  # Create a failed validation result
  mkFailed =
    {
      errors,
      warnings ? [ ],
    }:
    {
      passed = false;
      inherit errors warnings;
    };

  # Combine multiple validation results
  combineResults =
    results:
    let
      allPassed = lib.all (r: r.passed) results;
      allErrors = lib.concatLists (map (r: r.errors) results);
      allWarnings = lib.concatLists (map (r: r.warnings) results);
    in
    {
      passed = allPassed;
      errors = allErrors;
      warnings = allWarnings;
    };

  # ============================================================================
  # WCAG Contrast Calculation (WCAG 2.1)
  # ============================================================================
  # Based on WCAG 2.1 guidelines: https://www.w3.org/TR/WCAG21/#contrast-minimum
  #
  # Contrast Ratio = (L1 + 0.05) / (L2 + 0.05)
  # Where:
  #   L1 = relative luminance of lighter color
  #   L2 = relative luminance of darker color
  #
  # Relative luminance calculation:
  #   For each RGB component, convert to linear RGB:
  #     R_linear = (R/255) <= 0.03928 ? (R/255)/12.92 : ((R/255 + 0.055)/1.055)^2.4
  #     (same for G and B)
  #   Then: L = 0.2126 * R_linear + 0.7152 * G_linear + 0.0722 * B_linear

  # Convert sRGB component (0-255) to linear RGB (0.0-1.0)
  srgbToLinear =
    component:
    let
      normalized = component / 255.0;
    in
    if normalized <= 0.03928 then normalized / 12.92 else lib.pow ((normalized + 0.055) / 1.055) 2.4;

  # Calculate relative luminance from RGB values
  # Input: { r, g, b } where each is 0-255
  # Output: relative luminance (0.0-1.0)
  relativeLuminance =
    rgb:
    let
      rLinear = srgbToLinear rgb.r;
      gLinear = srgbToLinear rgb.g;
      bLinear = srgbToLinear rgb.b;
    in
    0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;

  # Calculate WCAG contrast ratio between two colors
  # Input: two color objects with rgb property
  # Output: contrast ratio (1.0-21.0, where 1.0 = no contrast, 21.0 = maximum)
  wcagContrastRatio =
    color1: color2:
    let
      l1 = relativeLuminance color1.rgb;
      l2 = relativeLuminance color2.rgb;
      lighter = lib.max l1 l2;
      darker = lib.min l1 l2;
    in
    (lighter + 0.05) / (darker + 0.05);

  # Check if contrast meets WCAG AA standard
  # - Normal text (body text): 4.5:1
  # - Large text (18pt+ or 14pt+ bold): 3:1
  wcagAANormal = ratio: ratio >= 4.5;
  wcagAALarge = ratio: ratio >= 3.0;

  # Check if contrast meets WCAG AAA standard
  # - Normal text: 7:1
  # - Large text: 4.5:1
  wcagAAANormal = ratio: ratio >= 7.0;
  wcagAAALarge = ratio: ratio >= 4.5;

  # ============================================================================
  # APCA Contrast Calculation (Advanced Perceptual Contrast Algorithm)
  # ============================================================================
  # Based on APCA: https://www.myndex.com/APCA/
  #
  # APCA provides a more perceptually uniform contrast calculation than WCAG.
  # It accounts for human vision and provides better predictions for readability.
  #
  # Note: This is a simplified implementation based on the APCA formula.
  # Full APCA requires additional context (spatial frequency, viewing conditions).
  # For theme validation, we use a simplified version that provides good results.

  # Convert sRGB to Y (luminance in the sRGB color space)
  # This is used for APCA calculations
  srgbToY =
    rgb:
    let
      rNorm = rgb.r / 255.0;
      gNorm = rgb.g / 255.0;
      bNorm = rgb.b / 255.0;
      # Convert to linear RGB
      rLin = if rNorm <= 0.04045 then rNorm / 12.92 else lib.pow ((rNorm + 0.055) / 1.055) 2.4;
      gLin = if gNorm <= 0.04045 then gNorm / 12.92 else lib.pow ((gNorm + 0.055) / 1.055) 2.4;
      bLin = if bNorm <= 0.04045 then bNorm / 12.92 else lib.pow ((bNorm + 0.055) / 1.055) 2.4;
    in
    # Convert to Y (luminance)
    0.2126729 * rLin + 0.7151522 * gLin + 0.0721750 * bLin;

  # Simplified APCA contrast calculation
  # Returns a contrast value (Lc) where:
  #   - Positive values = dark text on light background
  #   - Negative values = light text on dark background
  #   - Absolute value indicates contrast strength
  #
  # APCA thresholds:
  #   - 60+ = Excellent (body text)
  #   - 45+ = Good (body text)
  #   - 30+ = Minimum (large text)
  #   - 15+ = Minimum (UI elements)
  apcaContrast =
    textColor: backgroundColor:
    let
      Ytext = srgbToY textColor.rgb;
      Ybg = srgbToY backgroundColor.rgb;
      # Determine if text is lighter or darker than background
      isLightText = Ytext > Ybg;
      # Calculate contrast
      contrast =
        if isLightText then
          # Light text on dark background
          (lib.pow Ybg 0.446) - (lib.pow Ytext 0.446)
        else
          # Dark text on light background
          (lib.pow Ytext 0.446) - (lib.pow Ybg 0.446);
      # Scale to Lc units (multiply by 100)
      lc = contrast * 100.0;
    in
    # Return absolute value for comparison
    lib.abs lc;

  # Check if APCA contrast meets minimum standards
  apcaMinimum = lc: lc >= 15.0; # Minimum for UI elements
  apcaLargeText = lc: lc >= 30.0; # Minimum for large text
  apcaBodyText = lc: lc >= 45.0; # Good for body text
  apcaExcellent = lc: lc >= 60.0; # Excellent contrast

  # ============================================================================
  # Contrast Validation Functions
  # ============================================================================

  # Validate contrast between two colors using WCAG
  # Returns validation result
  validateContrastWCAG =
    {
      textColor,
      backgroundColor,
      level ? "AA",
      textSize ? "normal",
    }:
    let
      ratio = wcagContrastRatio textColor backgroundColor;
      meetsStandard =
        if level == "AAA" then
          if textSize == "large" then wcagAAALarge ratio else wcagAAANormal ratio
        else if textSize == "large" then
          wcagAALarge ratio
        else
          wcagAANormal ratio;
      standardName = "${level} ${textSize}";
      requiredRatio =
        if level == "AAA" then
          if textSize == "large" then 4.5 else 7.0
        else if textSize == "large" then
          3.0
        else
          4.5;
    in
    if meetsStandard then
      mkPassed { }
    else
      mkFailed {
        errors = [
          "Contrast ratio ${toString (lib.fixedWidthNumber 2 ratio)}:1 does not meet WCAG ${standardName} standard (requires ${toString requiredRatio}:1)"
        ];
      };

  # Validate contrast between two colors using APCA
  # Returns validation result
  validateContrastAPCA =
    {
      textColor,
      backgroundColor,
      textSize ? "normal",
    }:
    let
      lc = apcaContrast textColor backgroundColor;
      meetsStandard =
        if textSize == "large" then
          apcaLargeText lc
        else if textSize == "ui" then
          apcaMinimum lc
        else
          apcaBodyText lc;
      requiredLc =
        if textSize == "large" then
          30.0
        else if textSize == "ui" then
          15.0
        else
          45.0;
    in
    if meetsStandard then
      mkPassed { }
    else
      mkFailed {
        errors = [
          "APCA contrast ${toString (lib.fixedWidthNumber 1 lc)}Lc does not meet minimum for ${textSize} text (requires ${toString requiredLc}Lc)"
        ];
      };

  # Validate contrast using both WCAG and APCA
  # Returns combined validation result
  validateContrast =
    {
      textColor,
      backgroundColor,
      level ? "AA",
      textSize ? "normal",
      useAPCA ? false,
    }:
    let
      wcagResult = validateContrastWCAG {
        inherit
          textColor
          backgroundColor
          level
          textSize
          ;
      };
      apcaResult =
        if useAPCA then
          validateContrastAPCA { inherit textColor backgroundColor textSize; }
        else
          mkPassed { };
    in
    combineResults [
      wcagResult
      apcaResult
    ];

  # ============================================================================
  # Theme Completeness Validation
  # ============================================================================

  # Required semantic tokens that must exist in a theme
  requiredSemanticTokens = [
    # Surface colors
    "surface-base"
    "surface-subtle"
    "surface-emphasis"
    # Text colors
    "text-primary"
    "text-secondary"
    "text-tertiary"
    # Accent colors
    "accent-primary"
    "accent-danger"
    "accent-warning"
    "accent-info"
    # Syntax colors (minimum set)
    "syntax-keyword"
    "syntax-string"
    "syntax-comment"
    # ANSI colors (minimum set)
    "ansi-black"
    "ansi-white"
  ];

  # Validate that a theme has all required semantic tokens
  validateThemeCompleteness =
    theme:
    let
      colors = theme.colors;
      missing = lib.filter (token: !(colors ? ${token})) requiredSemanticTokens;
    in
    if missing == [ ] then
      mkPassed { }
    else
      mkFailed {
        errors = [
          "Theme is missing required semantic tokens: ${concatStringsSep ", " missing}"
        ];
      };

  # Validate that all colors have required properties
  validateColorStructure =
    color:
    let
      requiredProps = [
        "hex"
        "rgb"
        "l"
        "c"
        "h"
      ];
      missing = lib.filter (prop: !(color ? ${prop})) requiredProps;
    in
    if missing == [ ] then
      mkPassed { }
    else
      mkFailed {
        errors = [
          "Color is missing required properties: ${concatStringsSep ", " missing}"
        ];
      };

  # Validate all colors in a theme
  validateThemeColors =
    theme:
    let
      colors = theme.colors;
      colorResults = lib.mapAttrsToList (name: color: validateColorStructure color) colors;
    in
    combineResults colorResults;

  # ============================================================================
  # Accessibility Validation
  # ============================================================================

  # Critical text/background pairs that must meet contrast requirements
  criticalPairs =
    theme:
    let
      colors = theme.colors;
    in
    [
      # Primary text on base surface
      {
        name = "primary text on base surface";
        textColor = colors."text-primary" or null;
        backgroundColor = colors."surface-base" or null;
        textSize = "normal";
      }
      # Secondary text on base surface
      {
        name = "secondary text on base surface";
        textColor = colors."text-secondary" or null;
        backgroundColor = colors."surface-base" or null;
        textSize = "normal";
      }
      # Primary accent on base surface (for buttons, links)
      {
        name = "primary accent on base surface";
        textColor = colors."accent-primary" or null;
        backgroundColor = colors."surface-base" or null;
        textSize = "normal";
      }
      # Danger accent on base surface
      {
        name = "danger accent on base surface";
        textColor = colors."accent-danger" or null;
        backgroundColor = colors."surface-base" or null;
        textSize = "normal";
      }
    ];

  # Validate accessibility of critical color pairs
  validateAccessibility =
    {
      theme,
      level ? "AA",
      useAPCA ? false,
    }:
    let
      pairs = criticalPairs theme;
      # Filter out pairs with null colors
      validPairs = lib.filter (pair: pair.textColor != null && pair.backgroundColor != null) pairs;
      # Validate each pair
      pairResults = map (
        pair:
        let
          result = validateContrast {
            textColor = pair.textColor;
            backgroundColor = pair.backgroundColor;
            inherit level;
            textSize = pair.textSize;
            inherit useAPCA;
          };
        in
        if result.passed then
          result
        else
          mkFailed {
            errors = map (err: "${pair.name}: ${err}") result.errors;
            inherit (result) warnings;
          }
      ) validPairs;
    in
    combineResults pairResults;

  # ============================================================================
  # Main Validation Function
  # ============================================================================

  # Validate a complete theme
  # This runs all validation checks and returns a comprehensive result
  validateTheme =
    {
      theme,
      level ? "AA",
      textSize ? "normal",
      useAPCA ? false,
      strict ? false,
    }:
    let
      completeness = validateThemeCompleteness theme;
      colorStructure = validateThemeColors theme;
      accessibility = validateAccessibility { inherit theme level useAPCA; };
      allResults = [
        completeness
        colorStructure
        accessibility
      ];
      combined = combineResults allResults;
    in
    if strict && !combined.passed then
      throw "Theme validation failed:\n${concatStringsSep "\n" combined.errors}"
    else
      combined;

  # ============================================================================
  # Validation Report Generation
  # ============================================================================

  # Generate a human-readable validation report
  generateReport =
    result:
    let
      status = if result.passed then "PASSED" else "FAILED";
      errorSection =
        if result.errors != [ ] then
          "\nErrors:\n" + (concatStringsSep "\n" (map (e: "  - ${e}") result.errors))
        else
          "";
      warningSection =
        if result.warnings != [ ] then
          "\nWarnings:\n" + (concatStringsSep "\n" (map (w: "  - ${w}") result.warnings))
        else
          "";
    in
    "Validation ${status}${errorSection}${warningSection}";

  # Generate a machine-readable JSON report (as Nix attribute set)
  generateJSONReport = result: {
    passed = result.passed;
    errors = result.errors;
    warnings = result.warnings;
    errorCount = lib.length result.errors;
    warningCount = lib.length result.warnings;
  };

  # Generate summary statistics
  generateSummary = result: {
    passed = result.passed;
    totalErrors = lib.length result.errors;
    totalWarnings = lib.length result.warnings;
  };
in
{
  # Core validation functions
  inherit
    validateTheme
    validateContrast
    validateContrastWCAG
    validateContrastAPCA
    validateThemeCompleteness
    validateThemeColors
    validateAccessibility
    ;

  # Contrast calculation functions
  inherit
    wcagContrastRatio
    apcaContrast
    relativeLuminance
    ;

  # Report generation
  inherit
    generateReport
    generateJSONReport
    generateSummary
    ;

  # Result utilities
  inherit
    mkPassed
    mkFailed
    combineResults
    ;

  # Constants
  inherit
    requiredSemanticTokens
    ;
}
