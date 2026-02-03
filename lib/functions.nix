# Platform and System Utility Functions
# Provides helpers for cross-platform Nix configuration
{ lib }:
let
  # Platform detection
  isLinux = system: lib.hasSuffix "-linux" system;
  isDarwin = system: lib.hasSuffix "-darwin" system;

  # Cross-platform path helpers
  homeDir = system: username: if isDarwin system then "/Users/${username}" else "/home/${username}";
  configDir = system: username: "${homeDir system username}/.config";
  dataDir = system: username:
    if isDarwin system then
      "${homeDir system username}/Library/Application Support"
    else
      "${homeDir system username}/.local/share";
  cacheDir = system: username:
    if isDarwin system then
      "${homeDir system username}/Library/Caches"
    else
      "${homeDir system username}/.cache";

  # Package selection helpers
  platformPackage = system: linuxPkg: darwinPkg:
    if isDarwin system then darwinPkg else linuxPkg;
  platformPackages = system: linuxPkgs: darwinPkgs:
    if isDarwin system then darwinPkgs else linuxPkgs;

  # Pkgs configuration for nixpkgs import
  mkPkgsConfig = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
    allowBrokenPredicate = pkg:
      let
        name = toString (pkg.name or "");
      in
      lib.hasPrefix "zfs-kernel" name || name == "postgresql-test-hook";
    allowUnsupportedSystem = false;
  };

  # Build overlays list from overlay set
  mkOverlays = { inputs, system }: lib.attrValues (import ../overlays { inherit inputs system; });

  # Curry system-dependent functions
  withSystem = system: {
    inherit system;
    isLinux = isLinux system;
    isDarwin = isDarwin system;
    homeDir = homeDir system;
    configDir = configDir system;
    dataDir = dataDir system;
    cacheDir = cacheDir system;
    platformPackage = platformPackage system;
    platformPackages = platformPackages system;
  };

in
{
  inherit
    isLinux
    isDarwin
    homeDir
    configDir
    dataDir
    cacheDir
    platformPackage
    platformPackages
    mkPkgsConfig
    mkOverlays
    withSystem
    ;
}
