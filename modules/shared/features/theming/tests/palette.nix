{ }:
let
  # Import palette for testing
  palette = import ../palette.nix { };
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
  testBaseColorDark = {
    expr =
      palette.tonal.dark ? base-L015
      && palette.tonal.dark.base-L015 ? hex
      && palette.tonal.dark.base-L015 ? l
      && palette.tonal.dark.base-L015 ? c
      && palette.tonal.dark.base-L015 ? h
      && palette.tonal.dark.base-L015 ? rgb;
    expected = true;
  };

  testBaseColorLight = {
    expr =
      palette.tonal.light ? base-L095
      && palette.tonal.light.base-L095 ? hex
      && palette.tonal.light.base-L095 ? rgb;
    expected = true;
  };

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

  # Test chroma values are in valid range (0.0+)
  testChromaRange = {
    expr =
      let
        color = palette.accent.dark."Lc75-h130";
      in
      color.c >= 0.0;
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
        inherit (color) rgb;
      in
      rgb.r >= 0 && rgb.r <= 255 && rgb.g >= 0 && rgb.g <= 255 && rgb.b >= 0 && rgb.b <= 255;
    expected = true;
  };

  # Test all categorical colors (GA01-GA08) exist
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

  # Test that accent colors have variants
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

  # Test color consistency between light and dark modes
  testColorConsistency = {
    expr =
      let
        darkColor = palette.tonal.dark.base-L015;
        lightColor = palette.tonal.light.base-L095;
      in
      # Both should have same structure
      darkColor ? hex
      && darkColor ? rgb
      && darkColor ? l
      && lightColor ? hex
      && lightColor ? rgb
      && lightColor ? l;
    expected = true;
  };
}
