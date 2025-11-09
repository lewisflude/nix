{
  lib,
  pkgs,
  ...
}:
let
  # Import theme modules for testing (using shared palette - single source of truth)
  palette = import ../modules/shared/features/theming/palette.nix { inherit lib; };
  themeLib = import ../modules/shared/features/theming/lib.nix { inherit lib palette; };

  # Test helper
  testColor = name: color: {
    inherit name;
    assertion = color ? hex && color ? l && color ? c && color ? h;
    message = "Color ${name} must have hex, l, c, and h properties";
  };

  # Generate theme for testing (pass empty set for validation options)
  darkTheme = themeLib.generateTheme "dark" { };
  lightTheme = themeLib.generateTheme "light" { };
in
{
  # Test palette structure
  testPaletteStructure = {
    expr = palette ? tonal && palette ? accent && palette ? categorical;
    expected = true;
  };

  # Test tonal palette has both light and dark modes
  testTonalModes = {
    expr = palette.tonal ? light && palette.tonal ? dark;
    expected = true;
  };

  # Test accent palette has both modes
  testAccentModes = {
    expr = palette.accent ? light && palette.accent ? dark;
    expected = true;
  };

  # Test categorical palette has both modes
  testCategoricalModes = {
    expr = palette.categorical ? light && palette.categorical ? dark;
    expected = true;
  };

  # Test specific color exists and has required properties
  testBaseColorDark = testColor "base-L015" palette.tonal.dark.base-L015;

  testBaseColorLight = testColor "base-L095" palette.tonal.light.base-L095;

  testAccentPrimaryDark = testColor "Lc75-h130" palette.accent.dark."Lc75-h130";

  testAccentPrimaryLight = testColor "Lc75-h130" palette.accent.light."Lc75-h130";

  testCategoricalGA01Dark = testColor "GA01" palette.categorical.dark.GA01;

  testCategoricalGA01Light = testColor "GA01" palette.categorical.light.GA01;

  # Test hex color format
  testHexFormat = {
    expr = builtins.match "#[0-9a-f]{6}" palette.tonal.dark.base-L015.hex != null;
    expected = true;
  };

  # Test lightness values are in valid range (0.0-1.0)
  testLightnessRange = {
    expr =
      let
        color = palette.tonal.dark.base-L015;
      in
      color.l >= 0.0 && color.l <= 1.0;
    expected = true;
  };

  # Test chroma values are in valid range (0.0-0.4+)
  testChromaRange = {
    expr =
      let
        color = palette.accent.dark."Lc75-h130";
      in
      color.c >= 0.0 && color.c <= 1.0;
    expected = true;
  };

  # Test hue values are in valid range (0-360)
  testHueRange = {
    expr =
      let
        color = palette.accent.dark."Lc75-h130";
      in
      color.h >= 0.0 && color.h <= 360.0;
    expected = true;
  };

  # Test RGB values exist and are in valid range
  testRgbValues = {
    expr =
      let
        color = palette.tonal.dark.base-L015;
        rgb = color.rgb;
      in
      rgb.r >= 0 && rgb.r <= 255 && rgb.g >= 0 && rgb.g <= 255 && rgb.b >= 0 && rgb.b <= 255;
    expected = true;
  };

  # Test theme generation for dark mode
  testDarkThemeGeneration = {
    expr = darkTheme ? mode && darkTheme.mode == "dark";
    expected = true;
  };

  # Test theme generation for light mode
  testLightThemeGeneration = {
    expr = lightTheme ? mode && lightTheme.mode == "light";
    expected = true;
  };

  # Test semantic colors exist in generated theme
  testSemanticColorsDark = {
    expr = darkTheme.semantic ? "surface-base" && darkTheme.semantic ? "text-primary";
    expected = true;
  };

  testSemanticColorsLight = {
    expr = lightTheme.semantic ? "surface-base" && lightTheme.semantic ? "text-primary";
    expected = true;
  };

  # Test that semantic mappings are different between light and dark
  testLightDarkDifference = {
    expr = darkTheme.semantic."surface-base".hex != lightTheme.semantic."surface-base".hex;
    expected = true;
  };

  # Test all syntax highlighting colors exist
  testSyntaxColors = {
    expr =
      let
        sem = darkTheme.semantic;
      in
      sem ? "syntax-keyword"
      && sem ? "syntax-function-def"
      && sem ? "syntax-function-call"
      && sem ? "syntax-string"
      && sem ? "syntax-number"
      && sem ? "syntax-type"
      && sem ? "syntax-comment";
    expected = true;
  };

  # Test all ANSI terminal colors exist
  testAnsiColors = {
    expr =
      let
        sem = darkTheme.semantic;
      in
      sem ? "ansi-black"
      && sem ? "ansi-red"
      && sem ? "ansi-green"
      && sem ? "ansi-yellow"
      && sem ? "ansi-blue"
      && sem ? "ansi-magenta"
      && sem ? "ansi-cyan"
      && sem ? "ansi-white";
    expected = true;
  };

  # Test getPalette function
  testGetPaletteDark = {
    expr =
      let
        result = themeLib.getPalette "dark" palette.tonal;
      in
      result ? base-L015;
    expected = true;
  };

  testGetPaletteLight = {
    expr =
      let
        result = themeLib.getPalette "light" palette.tonal;
      in
      result ? base-L095;
    expected = true;
  };

  # Test getSemanticColors function
  testGetSemanticColorsDark = {
    expr =
      let
        result = themeLib.getSemanticColors "dark";
      in
      result ? "surface-base" && result ? "text-primary";
    expected = true;
  };

  # Test withAlpha function
  testWithAlpha = {
    expr =
      let
        theme = darkTheme;
        color = theme.semantic."accent-primary";
        withAlpha = theme.withAlpha color 0.5;
      in
      builtins.stringLength withAlpha > builtins.stringLength color.hex;
    expected = true;
  };

  # Test that all categorical colors (GA01-GA08) exist
  testAllCategoricalColors = {
    expr =
      let
        cat = palette.categorical.dark;
      in
      cat ? GA01
      && cat ? GA02
      && cat ? GA03
      && cat ? GA04
      && cat ? GA05
      && cat ? GA06
      && cat ? GA07
      && cat ? GA08;
    expected = true;
  };

  # Test that accent colors have all three variants
  testAccentVariants = {
    expr =
      let
        acc = palette.accent.dark;
      in
      acc ? "Lc75-h130" && acc ? "Lc60-h130" && acc ? "Lc45-h130";
    expected = true;
  };

  # Test all tonal colors exist
  testAllTonalColors = {
    expr =
      let
        tonal = palette.tonal.dark;
      in
      tonal ? base-L000
      && tonal ? base-L015
      && tonal ? surface-Lc05
      && tonal ? surface-Lc10
      && tonal ? divider-Lc15
      && tonal ? divider-Lc30
      && tonal ? text-Lc45
      && tonal ? text-Lc60
      && tonal ? text-Lc75;
    expected = true;
  };

  # Test contrast between text and background (approximate)
  testTextBackgroundContrast = {
    expr =
      let
        bg = darkTheme.semantic."surface-base";
        text = darkTheme.semantic."text-primary";
      in
      # In dark mode, text should be lighter than background
      text.l > bg.l;
    expected = true;
  };

  # Test that light mode has opposite contrast
  testLightModeContrast = {
    expr =
      let
        bg = lightTheme.semantic."surface-base";
        text = lightTheme.semantic."text-primary";
      in
      # In light mode, text should be darker than background
      text.l < bg.l;
    expected = true;
  };

  # Test getAnsiColorsList function
  testAnsiColorsList = {
    expr =
      let
        ansiList = themeLib.getAnsiColorsList "dark";
      in
      builtins.isList ansiList && builtins.length ansiList == 16;
    expected = true;
  };

  # Integration test: Verify theme can be used in a module context
  testModuleIntegration = {
    expr =
      let
        # Simulate a home-manager module config
        testModule = lib.evalModules {
          modules = [
            ../home/common/theming/default.nix
            {
              theming.signal = {
                enable = true;
                mode = "dark";
              };
            }
          ];
        };
      in
      testModule.config.theming.signal.enable;
    expected = true;
  };

  # Test that semantic colors maintain consistency
  testSemanticConsistency = {
    expr =
      let
        sem = darkTheme.semantic;
      in
      # Primary text should be brighter than secondary
      sem."text-primary".l > sem."text-secondary".l
      # Secondary should be brighter than tertiary
      && sem."text-secondary".l > sem."text-tertiary".l;
    expected = true;
  };

  # Test surface color progression
  testSurfaceProgression = {
    expr =
      let
        sem = darkTheme.semantic;
      in
      # In dark mode, surfaces should get lighter
      sem."surface-base".l < sem."surface-subtle".l && sem."surface-subtle".l < sem."surface-emphasis".l;
    expected = true;
  };

  # Test divider colors
  testDividerProgression = {
    expr =
      let
        sem = darkTheme.semantic;
      in
      # Secondary divider should be more prominent (lighter in dark mode)
      sem."divider-primary".l < sem."divider-secondary".l;
    expected = true;
  };
}
