# Platform and System Utility Functions
# Simplified to include only essential cross-platform helpers
{ lib }:
let
  constants = import ./constants.nix;

  # Platform detection (simple helpers)
  isLinux = system: lib.hasSuffix "-linux" system;
  isDarwin = system: lib.hasSuffix "-darwin" system;

  # Cross-platform path helpers (actually useful!)
  homeDir = system: username: if isDarwin system then "/Users/${username}" else "/home/${username}";

  configDir = system: username: "${homeDir system username}/.config";

  dataDir =
    system: username:
    if isDarwin system then
      "${homeDir system username}/Library/Application Support"
    else
      "${homeDir system username}/.local/share";

  cacheDir =
    system: username:
    if isDarwin system then
      "${homeDir system username}/Library/Caches"
    else
      "${homeDir system username}/.cache";

  # Platform-specific state version
  platformStateVersion =
    system:
    if isDarwin system then constants.defaults.darwinStateVersion else constants.defaults.stateVersion;

  # Platform-specific package selection
  # Selects a single package based on platform
  platformPackage =
    system: linuxPkg: darwinPkg:
    if isDarwin system then darwinPkg else linuxPkg;

  # Platform-specific package list selection
  # Selects a list of packages based on platform
  platformPackages =
    system: linuxPkgs: darwinPkgs:
    if isDarwin system then darwinPkgs else linuxPkgs;

  # Build home-manager special args
  mkHomeManagerExtraSpecialArgs =
    {
      inputs,
      hostConfig,
      includeUserFields ? true,
    }:
    let
      # Shared resources (eliminates fragile relative imports)
      constants = import ../lib/constants.nix;
      palette = import ../modules/shared/features/theming/palette.nix { };
      themeLib = import ../modules/shared/features/theming/lib.nix {
        inherit lib;
        palette = import ../modules/shared/features/theming/palette.nix { };
      };
    in
    inputs
    // hostConfig
    // {
      inherit inputs;
      inherit (hostConfig) system;
      hostSystem = hostConfig.system;
      host = hostConfig;
      inherit (inputs) nix-colorizer;
      # Add shared resources
      inherit constants palette themeLib;
    }
    // lib.optionalAttrs includeUserFields {
      inherit (hostConfig) username useremail hostname;
    }
    // {
      virtualisation = hostConfig.features.virtualisation or { };
    };

  # PKgs configuration
  mkPkgsConfig = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
    allowBrokenPredicate =
      pkg:
      let
        name = toString (pkg.name or "");
      in
      lib.hasPrefix "zfs-kernel" name || name == "postgresql-test-hook";
    allowUnsupportedSystem = false;
  };

  # Build overlays list from overlay set
  mkOverlays = { inputs, system }: lib.attrValues (import ../overlays { inherit inputs system; });

  # withSystem: Curry system-dependent functions
  withSystem = system: {
    inherit system;
    isLinux = isLinux system;
    isDarwin = isDarwin system;
    homeDir = homeDir system;
    configDir = configDir system;
    dataDir = dataDir system;
    cacheDir = cacheDir system;
    platformStateVersion = platformStateVersion system;
    platformPackage = platformPackage system;
    platformPackages = platformPackages system;
  };

in
{
  # Exports
  inherit
    isLinux
    isDarwin
    homeDir
    configDir
    dataDir
    cacheDir
    platformStateVersion
    platformPackage
    platformPackages
    mkHomeManagerExtraSpecialArgs
    mkPkgsConfig
    mkOverlays
    withSystem
    ;
}
