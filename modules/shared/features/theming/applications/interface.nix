{ lib }:
let
  inherit (lib) types;
in
rec {
  # Standard application interface
  # All application modules should conform to this interface
  # This provides consistency and enables generic application loading

  # Application interface type definition
  # This is a conceptual type - in practice, applications return config fragments
  applicationInterface = {
    # Whether the application theme is enabled
    enable = types.bool;

    # Application-specific theme configuration
    # This is the actual config that gets applied (home-manager, nixos config, etc.)
    themeConfig = types.attrs; # Flexible attribute set

    # Generated theme files (if any)
    # List of file paths that are created by the theme module
    themeFiles = types.listOf types.path;

    # Required packages for this application
    # List of package derivations
    themeDependencies = types.listOf types.package;

    # Platform this application targets
    # "nixos", "home", or "both"
    platform = types.enum [
      "nixos"
      "home"
      "both"
    ];
  };

  # Validate that an application module conforms to the interface
  # This is a runtime check that can be used during development
  validateApplication =
    app:
    let
      requiredFields = [
        "enable"
        "themeConfig"
        "platform"
      ];
      missingFields = lib.filter (field: !(app ? ${field})) requiredFields;
    in
    if missingFields != [ ] then
      throw "Application module is missing required fields: ${lib.concatStringsSep ", " missingFields}"
    else if
      !builtins.elem app.platform [
        "nixos"
        "home"
        "both"
      ]
    then
      throw "Application has invalid platform: ${app.platform}. Must be 'nixos', 'home', or 'both'"
    else
      app;

  # Check if application conforms to interface (non-throwing)
  isValidApplication =
    app:
    let
      result = builtins.tryEval (validateApplication app);
    in
    result.success;

  # Helper to create a standard application module structure
  # This provides a template for new application modules
  mkApplicationModule =
    {
      name,
      platform,
      enable ? true,
      themeConfig ? { },
      themeFiles ? [ ],
      themeDependencies ? [ ],
    }:
    {
      inherit
        enable
        themeConfig
        themeFiles
        themeDependencies
        platform
        ;
      _name = name;
    };
}
