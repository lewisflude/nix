# Shared library functions
# Dendritic pattern: Exposes myLib as a top-level option (like config.constants)
{ lib, ... }:
let
  myLib = rec {
    # Platform detection
    isLinux = system: lib.hasSuffix "-linux" system;
    isDarwin = system: lib.hasSuffix "-darwin" system;

    # Cross-platform path helpers (composed from homeDir)
    homeDir = system: username: if isDarwin system then "/Users/${username}" else "/home/${username}";
    configDir = system: username: "${homeDir system username}/.config";
    dataDir =
      system: username:
      if isDarwin system then
        "${homeDir system username}/Library/Application Support"
      else
        "${homeDir system username}/.local/share";

    # Pkgs configuration for nixpkgs import
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
  };
in
{
  options.myLib = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = myLib;
    description = "Shared library functions (platform detection, path helpers, pkgs config)";
  };

  config.flake.lib = myLib;
}
