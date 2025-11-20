{ lib }:
let
  # Import validation module
  validationLib = import ../validation.nix { inherit lib; };

  # Import palette and theme for testing
  palette = import ../palette.nix { };
  themeLib = import ../lib.nix {
    inherit lib palette;
  };

  # Generate test theme
  testTheme = themeLib.generateTheme "dark" { };

  # Test colors with known contrast ratios
  # White on black should have maximum contrast
  whiteColor = {
    hex = "#ffffff";
    rgb = {
      r = 255;
      g = 255;
      b = 255;
    };
    l = 1.0;
    c = 0.0;
    h = 0.0;
  };

  blackColor = {
    hex = "#000000";
    rgb = {
      r = 0;
      g = 0;
      b = 0;
    };
    l = 0.0;
    c = 0.0;
    h = 0.0;
  };
in
{
  # Test WCAG contrast calculation
  testWcagContrastWhiteBlack = {
    expr =
      let
        ratio = validationLib.wcagContrastRatio whiteColor blackColor;
      in
      # White on black should have ~21:1 contrast (maximum)
      ratio >= 20.0 && ratio <= 21.0;
    expected = true;
  };

  testWcagContrastSameColor = {
    expr =
      let
        ratio = validationLib.wcagContrastRatio whiteColor whiteColor;
      in
      # Same color should have 1:1 contrast (minimum)
      ratio >= 1.0 && ratio <= 1.01;
    expected = true;
  };

  # Test relative luminance
  testRelativeLuminanceWhite = {
    expr =
      let
        lum = validationLib.relativeLuminance whiteColor.rgb;
      in
      # White should have luminance of 1.0
      lum >= 0.99 && lum <= 1.01;
    expected = true;
  };

  testRelativeLuminanceBlack = {
    expr =
      let
        lum = validationLib.relativeLuminance blackColor.rgb;
      in
      # Black should have luminance of 0.0
      lum >= 0.0 && lum <= 0.01;
    expected = true;
  };

  # Test contrast validation
  testValidateContrastWCAG = {
    expr =
      let
        result = validationLib.validateContrastWCAG {
          textColor = whiteColor;
          backgroundColor = blackColor;
          level = "AA";
          textSize = "normal";
        };
      in
      result.passed;
    expected = true;
  };

  testValidateContrastWCAGFails = {
    expr =
      let
        # Two similar colors should fail
        color1 = {
          hex = "#aaaaaa";
          rgb = {
            r = 170;
            g = 170;
            b = 170;
          };
          l = 0.67;
          c = 0.0;
          h = 0.0;
        };
        color2 = {
          hex = "#bbbbbb";
          rgb = {
            r = 187;
            g = 187;
            b = 187;
          };
          l = 0.73;
          c = 0.0;
          h = 0.0;
        };
        result = validationLib.validateContrastWCAG {
          textColor = color1;
          backgroundColor = color2;
          level = "AA";
          textSize = "normal";
        };
      in
      !result.passed;
    expected = true;
  };

  # Test theme completeness validation
  testValidateThemeCompleteness = {
    expr =
      let
        result = validationLib.validateThemeCompleteness testTheme;
      in
      result.passed;
    expected = true;
  };

  testValidateThemeCompletenessFails = {
    expr =
      let
        incompleteTheme = {
          mode = "dark";
          colors = {
            "surface-base" = testTheme.colors."surface-base";
            # Missing other required tokens
          };
        };
        result = validationLib.validateThemeCompleteness incompleteTheme;
      in
      !result.passed && result.errors != [ ];
    expected = true;
  };

  # Test color structure validation
  testValidateColorStructure = {
    expr =
      let
        validColor = testTheme.colors."text-primary";
        result = validationLib.validateColorStructure validColor;
      in
      result.passed;
    expected = true;
  };

  testValidateColorStructureFails = {
    expr =
      let
        invalidColor = {
          hex = "#ffffff";
        }; # Missing rgb, l, c, h
        result = validationLib.validateColorStructure invalidColor;
      in
      !result.passed && result.errors != [ ];
    expected = true;
  };

  # Test accessibility validation
  testValidateAccessibility = {
    expr =
      let
        result = validationLib.validateAccessibility {
          theme = testTheme;
          level = "AA";
          useAPCA = false;
        };
      in
      result.passed;
    expected = true;
  };

  # Test full theme validation
  testValidateTheme = {
    expr =
      let
        result = validationLib.validateTheme {
          theme = testTheme;
          level = "AA";
          textSize = "normal";
          useAPCA = false;
          strict = false;
        };
      in
      result.passed;
    expected = true;
  };

  # Test validation result combination
  testCombineResults = {
    expr =
      let
        result1 = validationLib.mkPassed { };
        result2 = validationLib.mkPassed { };
        combined = validationLib.combineResults [
          result1
          result2
        ];
      in
      combined.passed && combined.errors == [ ] && combined.warnings == [ ];
    expected = true;
  };

  testCombineResultsWithErrors = {
    expr =
      let
        result1 = validationLib.mkPassed { };
        result2 = validationLib.mkFailed { errors = [ "Test error" ]; };
        combined = validationLib.combineResults [
          result1
          result2
        ];
      in
      !combined.passed && combined.errors == [ "Test error" ];
    expected = true;
  };

  # Test report generation
  testGenerateReport = {
    expr =
      let
        result = validationLib.mkPassed { };
        report = validationLib.generateReport result;
      in
      builtins.stringLength report > 0 && lib.hasPrefix "PASSED" report;
    expected = true;
  };

  testGenerateReportWithErrors = {
    expr =
      let
        result = validationLib.mkFailed { errors = [ "Test error" ]; };
        report = validationLib.generateReport result;
      in
      builtins.stringLength report > 0 && lib.hasPrefix "FAILED" report;
    expected = true;
  };

  # Test JSON report generation
  testGenerateJSONReport = {
    expr =
      let
        result = validationLib.mkPassed { };
        json = validationLib.generateJSONReport result;
      in
      json.passed && json.errorCount == 0 && json.warningCount == 0;
    expected = true;
  };

  # Test summary generation
  testGenerateSummary = {
    expr =
      let
        result = validationLib.mkPassed { };
        summary = validationLib.generateSummary result;
      in
      summary.passed && summary.totalErrors == 0;
    expected = true;
  };
}
