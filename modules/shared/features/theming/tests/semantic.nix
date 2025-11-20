{ lib }:
let
  # Import theme modules
  palette = import ../palette.nix { };
  themeLib = import ../lib.nix {
    inherit lib palette;
  };

  # Generate themes for testing
  darkTheme = themeLib.generateTheme "dark" { };
  lightTheme = themeLib.generateTheme "light" { };
in
{
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
    expr = darkTheme.colors ? "surface-base" && darkTheme.colors ? "text-primary";
    expected = true;
  };

  testSemanticColorsLight = {
    expr = lightTheme.colors ? "surface-base" && lightTheme.colors ? "text-primary";
    expected = true;
  };

  # Test that semantic mappings are different between light and dark
  testLightDarkDifference = {
    expr = darkTheme.colors."surface-base".hex != lightTheme.colors."surface-base".hex;
    expected = true;
  };

  # Test all syntax highlighting colors exist
  testSyntaxColors = {
    expr =
      let
        sem = darkTheme.colors;
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
        sem = darkTheme.colors;
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

  # Test getSemanticColors function
  testGetSemanticColorsDark = {
    expr =
      let
        result = themeLib.getSemanticColors "dark";
      in
      result ? "surface-base" && result ? "text-primary";
    expected = true;
  };

  # Test semantic color consistency
  testSemanticConsistency = {
    expr =
      let
        sem = darkTheme.colors;
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
        sem = darkTheme.colors;
      in
      # In dark mode, surfaces should get lighter
      sem."surface-base".l < sem."surface-subtle".l && sem."surface-subtle".l < sem."surface-emphasis".l;
    expected = true;
  };

  # Test divider colors
  testDividerProgression = {
    expr =
      let
        sem = darkTheme.colors;
      in
      # Secondary divider should be more prominent (lighter in dark mode)
      sem."divider-primary".l < sem."divider-secondary".l;
    expected = true;
  };

  # Test withAlpha function
  testWithAlpha = {
    expr =
      let
        theme = darkTheme;
        color = theme.colors."accent-primary";
        withAlpha = theme.withAlpha color 0.5;
      in
      builtins.stringLength withAlpha > builtins.stringLength color.hex;
    expected = true;
  };

  # Test ANSI colors list
  testAnsiColorsList = {
    expr =
      let
        ansiList = themeLib.getAnsiColorsList "dark";
      in
      builtins.isList ansiList && builtins.length ansiList == 16;
    expected = true;
  };
}
