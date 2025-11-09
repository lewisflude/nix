{ lib }:
let
  # Import application registry
  registry = import ../applications/registry.nix { inherit lib; };

  # Import interface
  interface = import ../applications/interface.nix { inherit lib; };
in
{
  # Test registry structure
  testRegistryExists = {
    expr = registry ? applications && registry ? getByPlatform && registry ? getByCategory;
    expected = true;
  };

  # Test all applications are registered
  testAllApplicationsRegistered = {
    expr =
      let
        apps = registry.getAll;
      in
      apps ? cursor && apps ? helix && apps ? zed && apps ? ghostty && apps ? bat && apps ? fzf;
    expected = true;
  };

  # Test registry query functions
  testGetByPlatform = {
    expr =
      let
        homeApps = registry.getByPlatform "home";
      in
      builtins.isAttrs homeApps && homeApps ? cursor;
    expected = true;
  };

  testGetByCategory = {
    expr =
      let
        editors = registry.getByCategory "editor";
      in
      builtins.isAttrs editors && editors ? cursor && editors ? helix && editors ? zed;
    expected = true;
  };

  testGetByName = {
    expr =
      let
        cursor = registry.getByName "cursor";
      in
      cursor != null && cursor.name == "cursor";
    expected = true;
  };

  testGetByNameNotFound = {
    expr = registry.getByName "nonexistent" == null;
    expected = true;
  };

  # Test application metadata structure
  testApplicationMetadata = {
    expr =
      let
        cursor = registry.getByName "cursor";
      in
      cursor ? name
      && cursor ? platform
      && cursor ? category
      && cursor ? description
      && cursor ? modulePath;
    expected = true;
  };

  # Test interface validation
  testValidateApplication = {
    expr =
      let
        validApp = {
          enable = true;
          themeConfig = { };
          platform = "home";
          themeFiles = [ ];
          themeDependencies = [ ];
        };
        result = builtins.tryEval (interface.validateApplication validApp);
      in
      result.success;
    expected = true;
  };

  testValidateApplicationFails = {
    expr =
      let
        invalidApp = {
          enable = true;
          # Missing themeConfig and platform
        };
        result = builtins.tryEval (interface.validateApplication invalidApp);
      in
      !result.success;
    expected = true;
  };

  # Test isValidApplication (non-throwing)
  testIsValidApplication = {
    expr =
      let
        validApp = {
          enable = true;
          themeConfig = { };
          platform = "home";
        };
      in
      interface.isValidApplication validApp;
    expected = true;
  };

  testIsValidApplicationInvalid = {
    expr =
      let
        invalidApp = {
          enable = true;
          # Missing required fields
        };
      in
      !(interface.isValidApplication invalidApp);
    expected = true;
  };

  # Test mkApplicationModule helper
  testMkApplicationModule = {
    expr =
      let
        app = interface.mkApplicationModule {
          name = "test";
          platform = "home";
          enable = true;
        };
      in
      app.enable && app.platform == "home" && app._name == "test";
    expected = true;
  };
}
