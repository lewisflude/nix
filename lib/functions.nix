# Platform and System Utility Functions
# Simplified to include only essential cross-platform helpers
{ lib }:
let
  # Platform detection (simple helpers)
  isLinux = system: lib.hasSuffix "-linux" system;
  isDarwin = system: lib.hasSuffix "-darwin" system;

  # Cross-platform path helpers (actually useful!)
  homeDir = system: username:
    if isDarwin system then "/Users/${username}" else "/home/${username}";

  configDir = system: username:
    "${homeDir system username}/.config";

  dataDir = system: username:
    if isDarwin system
    then "${homeDir system username}/Library/Application Support"
    else "${homeDir system username}/.local/share";

  cacheDir = system: username:
    if isDarwin system
    then "${homeDir system username}/Library/Caches"
    else "${homeDir system username}/.cache";

  # Platform-specific state version
  platformStateVersion = system:
    if isDarwin system then 6 else "25.05";

  # Build home-manager special args
  mkHomeManagerExtraSpecialArgs = { inputs, hostConfig, includeUserFields ? true }:
    inputs // hostConfig // {
      inherit inputs;
      inherit (hostConfig) system;
      hostSystem = hostConfig.system;
      host = hostConfig;
      inherit (inputs) nix-colorizer;
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
    allowBrokenPredicate = pkg: lib.hasPrefix "zfs-kernel" (toString (pkg.name or ""));
    allowUnsupportedSystem = false;
  };

  # Build overlays list from overlay set
  mkOverlays = { inputs, system }:
    lib.attrValues (import ../overlays { inherit inputs system; });

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
    mkHomeManagerExtraSpecialArgs
    mkPkgsConfig
    mkOverlays
    withSystem
    ;
}
