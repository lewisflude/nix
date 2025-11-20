{ lib }:
let
  # Import theme modules
  palette = import ../palette.nix { };
  themeLib = import ../lib.nix {
    inherit lib palette;
  };

  # Generate themes
  darkTheme = themeLib.generateTheme "dark" { };
  lightTheme = themeLib.generateTheme "light" { };
in
{
  # Snapshot tests: Verify that generated themes have expected structure
  # These tests ensure that theme generation produces consistent output

  # Test theme has all expected top-level keys
  testThemeStructure = {
    expr =
      darkTheme ? mode
      && darkTheme ? colors
      && darkTheme ? semantic
      && darkTheme ? _internal
      && darkTheme ? withAlpha
      && darkTheme ? toOklch
      && darkTheme ? toRgb
      && darkTheme ? formats;
    expected = true;
  };

  # Test that semantic colors match colors (backward compatibility)
  testSemanticColorsMatch = {
    expr = darkTheme.colors == darkTheme.semantic;
    expected = true;
  };

  # Test that _internal contains expected palettes
  testInternalPalettes = {
    expr =
      darkTheme._internal ? tonal
      && darkTheme._internal ? accent
      && darkTheme._internal ? categorical
      && darkTheme._internal ? semantic;
    expected = true;
  };

  # Test format conversion functions
  testFormatFunctions = {
    expr =
      darkTheme.formats ? hex
      && darkTheme.formats ? hexRaw
      && darkTheme.formats ? rgb
      && darkTheme.formats ? rgbString
      && darkTheme.formats ? rgbNormalized
      && darkTheme.formats ? rgbNormalizedString
      && darkTheme.formats ? oklch;
    expected = true;
  };

  # Test format conversion works
  testFormatHex = {
    expr =
      let
        color = darkTheme.colors."text-primary";
        hex = darkTheme.formats.hex color;
      in
      builtins.stringLength hex == 7 && lib.hasPrefix "#" hex;
    expected = true;
  };

  testFormatRgb = {
    expr =
      let
        color = darkTheme.colors."text-primary";
        rgb = darkTheme.formats.rgb color;
      in
      rgb ? r
      && rgb ? g
      && rgb ? b
      && rgb.r >= 0
      && rgb.r <= 255
      && rgb.g >= 0
      && rgb.g <= 255
      && rgb.b >= 0
      && rgb.b <= 255;
    expected = true;
  };

  testFormatOklch = {
    expr =
      let
        color = darkTheme.colors."text-primary";
        oklch = darkTheme.formats.oklch color;
      in
      lib.hasPrefix "oklch(" oklch;
    expected = true;
  };

  # Test that dark and light themes have same structure
  testThemeStructureConsistency = {
    expr =
      darkTheme ? mode
      && lightTheme ? mode
      && darkTheme ? colors
      && lightTheme ? colors
      && darkTheme ? formats
      && lightTheme ? formats;
    expected = true;
  };

  # Test that all semantic tokens exist in both modes
  testSemanticTokensConsistency = {
    expr =
      let
        darkTokens = lib.attrNames darkTheme.colors;
        lightTokens = lib.attrNames lightTheme.colors;
      in
      # Both should have the same set of tokens
      lib.length darkTokens == lib.length lightTokens
      && lib.all (token: lib.elem token lightTokens) darkTokens;
    expected = true;
  };

  # Test that withAlpha produces valid output
  testWithAlphaOutput = {
    expr =
      let
        color = darkTheme.colors."accent-primary";
        withAlpha = darkTheme.withAlpha color 0.5;
      in
      # Should be longer than hex (has alpha channel)
      builtins.stringLength withAlpha == 9 && lib.hasPrefix "#" withAlpha;
    expected = true;
  };

  # Test that toOklch produces valid output
  testToOklchOutput = {
    expr =
      let
        color = darkTheme.colors."accent-primary";
        oklch = darkTheme.toOklch color;
      in
      lib.hasPrefix "oklch(" oklch;
    expected = true;
  };

  # Test that toRgb produces valid output
  testToRgbOutput = {
    expr =
      let
        color = darkTheme.colors."accent-primary";
        rgb = darkTheme.toRgb color;
      in
      lib.hasPrefix "rgb(" rgb;
    expected = true;
  };
}
