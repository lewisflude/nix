{ lib }:
let
  # Import mode resolution module
  modeLib = import ../mode.nix {
    inherit lib;
    config = null;
  };
in
{
  # Test mode validation
  testIsValidMode = {
    expr = modeLib.isValidMode "dark" && modeLib.isValidMode "light" && modeLib.isValidMode "auto";
    expected = true;
  };

  testIsInvalidMode = {
    expr = !(modeLib.isValidMode "invalid");
    expected = true;
  };

  # Test mode normalization
  testNormalizeMode = {
    expr =
      modeLib.normalizeMode "dark" == "dark"
      && modeLib.normalizeMode "light" == "light"
      && modeLib.normalizeMode "auto" == "auto";
    expected = true;
  };

  # Test mode normalization throws on invalid mode
  testNormalizeModeThrows = {
    expr =
      let
        result = builtins.tryEval (modeLib.normalizeMode "invalid");
      in
      !result.success;
    expected = true;
  };

  # Test mode resolution (auto should default to dark when config is null)
  testResolveModeAuto = {
    expr = modeLib.resolveMode "auto" == "dark";
    expected = true;
  };

  testResolveModeLight = {
    expr = modeLib.resolveMode "light" == "light";
    expected = true;
  };

  testResolveModeDark = {
    expr = modeLib.resolveMode "dark" == "dark";
    expected = true;
  };

  # Test mode comparison
  testModesEqual = {
    expr =
      modeLib.modesEqual "dark" "dark"
      && modeLib.modesEqual "light" "light"
      && !(modeLib.modesEqual "dark" "light");
    expected = true;
  };

  # Test getResolvedMode with config
  testGetResolvedMode = {
    expr =
      let
        cfg = {
          mode = "dark";
        };
      in
      modeLib.getResolvedMode cfg == "dark";
    expected = true;
  };

  testGetResolvedModeDefault = {
    expr =
      let
        cfg = { };
      in
      modeLib.getResolvedMode cfg == "dark";
    expected = true;
  };

  testGetResolvedModeAuto = {
    expr =
      let
        cfg = {
          mode = "auto";
        };
      in
      modeLib.getResolvedMode cfg == "dark"; # Should default to dark
    expected = true;
  };
}
