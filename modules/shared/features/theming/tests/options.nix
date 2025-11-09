{ lib }:
let
  # Import options module
  optionsModule = import ../options.nix { inherit lib; };

  # Test that we can evaluate options
  testModule = lib.evalModules {
    modules = [ optionsModule ];
  };
in
{
  # Test options structure exists
  testOptionsStructure = {
    expr = testModule.options ? theming && testModule.options.theming ? signal;
    expected = true;
  };

  # Test enable option exists
  testEnableOption = {
    expr = testModule.options.theming.signal ? enable;
    expected = true;
  };

  # Test mode option exists
  testModeOption = {
    expr = testModule.options.theming.signal ? mode;
    expected = true;
  };

  # Test mode option has correct type
  testModeOptionType = {
    expr =
      let
        opt = testModule.options.theming.signal.mode;
      in
      opt.type.name == "enum";
    expected = true;
  };

  # Test mode option default
  testModeOptionDefault = {
    expr =
      let
        cfg = testModule.config;
      in
      cfg.theming.signal.mode == "dark";
    expected = true;
  };

  # Test brand governance options exist
  testBrandGovernanceOptions = {
    expr =
      testModule.options.theming.signal ? brandGovernance
      && testModule.options.theming.signal.brandGovernance ? policy
      && testModule.options.theming.signal.brandGovernance ? decorativeBrandColors
      && testModule.options.theming.signal.brandGovernance ? brandColors;
    expected = true;
  };

  # Test brand governance policy default
  testBrandGovernancePolicyDefault = {
    expr =
      let
        cfg = testModule.config;
      in
      cfg.theming.signal.brandGovernance.policy == "functional-override";
    expected = true;
  };

  # Test overrides option exists (deprecated)
  testOverridesOption = {
    expr = testModule.options.theming.signal ? overrides;
    expected = true;
  };

  # Test overrides option default
  testOverridesOptionDefault = {
    expr =
      let
        cfg = testModule.config;
      in
      cfg.theming.signal.overrides == { };
    expected = true;
  };

  # Test validation options exist
  testValidationOptions = {
    expr =
      testModule.options.theming.signal ? validation
      && testModule.options.theming.signal.validation ? enable
      && testModule.options.theming.signal.validation ? strictMode
      && testModule.options.theming.signal.validation ? level
      && testModule.options.theming.signal.validation ? validationLevel
      && testModule.options.theming.signal.validation ? useAPCA;
    expected = true;
  };

  # Test validation options defaults
  testValidationOptionsDefaults = {
    expr =
      let
        cfg = testModule.config;
        inherit (cfg.theming.signal) validation;
      in
      !validation.enable
      && !validation.strictMode
      && validation.level == "AA"
      && validation.validationLevel == "standard"
      && !validation.useAPCA;
    expected = true;
  };

  # Test that options can be set
  testSetOptions = {
    expr =
      let
        testModule2 = lib.evalModules {
          modules = [
            optionsModule
            {
              theming.signal = {
                enable = true;
                mode = "light";
                validation.enable = true;
              };
            }
          ];
        };
        cfg = testModule2.config;
      in
      cfg.theming.signal.enable
      && cfg.theming.signal.mode == "light"
      && cfg.theming.signal.validation.enable;
    expected = true;
  };
}
