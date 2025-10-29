{lib}: rec {
  # Version management
  versions = {
    nodejs = "nodejs_24"; # Latest LTS version with full binary cache support
    python = "python313";
    go = "go";
    rust = {
      package = "rustc";
      cargo = "cargo";
    };
  };

  getVersionedPackage = pkgs: packageName: lib.getAttr packageName pkgs;

  # Helper to create a system-bound version of all platform functions
  # Usage: platformLib = (import ./lib/functions.nix {inherit lib;}).withSystem system;
  withSystem = system: {
    inherit system versions getVersionedPackage getVirtualisationFlag;

    # System detection
    isLinux = isLinux system;
    isDarwin = isDarwin system;
    isAarch64 = isAarch64 system;
    isX86_64 = isX86_64 system;
    isLinuxX86_64 = isLinuxX86_64 system;
    isLinuxAarch64 = isLinuxAarch64 system;
    isDarwinX86_64 = isDarwinX86_64 system;
    isDarwinAarch64 = isDarwinAarch64 system;

    # Platform selectors (already bound to system)
    ifLinux = ifLinux system;
    ifDarwin = ifDarwin system;
    platformPackages = platformPackages system;
    archPackages = archPackages system;
    platformModules = platformModules system;
    platformConfig = platformConfig system;
    platformPackage = platformPackage system;

    # Paths (already bound to system)
    homeDir = homeDir system;
    configDir = configDir system;
    dataDir = dataDir system;
    cacheDir = cacheDir system;

    # Constants
    rootGroup = rootGroup system;
    platformStateVersion = platformStateVersion system;

    # Helpers
    enableSystemService = enableSystemService system;
    brewPackages = brewPackages system;
    systemRebuildCommand = systemRebuildCommand system;
  };

  # System detection helpers (pure functions that take system as parameter)
  isLinux = system: lib.hasInfix "linux" system;
  isDarwin = system: lib.hasInfix "darwin" system;
  isAarch64 = system: lib.hasInfix "aarch64" system;
  isX86_64 = system: lib.hasInfix "x86_64" system;

  # Composite system checks
  isLinuxX86_64 = system: isLinux system && isX86_64 system;
  isLinuxAarch64 = system: isLinux system && isAarch64 system;
  isDarwinX86_64 = system: isDarwin system && isX86_64 system;
  isDarwinAarch64 = system: isDarwin system && isAarch64 system;

  # Platform-specific value selectors
  ifLinux = system: value: lib.optionalAttrs (isLinux system) value;
  ifDarwin = system: value: lib.optionalAttrs (isDarwin system) value;

  platformPackages = system: linuxPkgs: darwinPkgs:
    (lib.optionals (isLinux system) linuxPkgs) ++ (lib.optionals (isDarwin system) darwinPkgs);

  archPackages = system: x86Pkgs: aarch64Pkgs:
    (lib.optionals (isX86_64 system) x86Pkgs) ++ (lib.optionals (isAarch64 system) aarch64Pkgs);

  platformModules = system: linuxModules: darwinModules:
    (lib.optionals (isLinux system) linuxModules) ++ (lib.optionals (isDarwin system) darwinModules);

  platformConfig = system: linuxConfig: darwinConfig:
    if isLinux system
    then linuxConfig
    else darwinConfig;

  platformPackage = system: linuxPkg: darwinPkg:
    if isLinux system
    then linuxPkg
    else darwinPkg;

  # Platform-specific paths
  homeDir = system: username:
    if isDarwin system
    then "/Users/${username}"
    else "/home/${username}";

  configDir = system: username: "${homeDir system username}/.config";

  dataDir = system: username:
    if isDarwin system
    then "${homeDir system username}/Library/Application Support"
    else "${homeDir system username}/.local/share";

  cacheDir = system: username:
    if isDarwin system
    then "${homeDir system username}/Library/Caches"
    else "${homeDir system username}/.cache";

  # Platform-specific constants
  rootGroup = system:
    if isDarwin system
    then "wheel"
    else "root";

  platformStateVersion = system:
    if isDarwin system
    then 6
    else "25.05";

  # System service helpers
  enableSystemService = system: serviceName:
    lib.mkIf (isLinux system) {
      systemd.user.services.${serviceName}.enable = true;
    };

  brewPackages = system: packages:
    lib.mkIf (isDarwin system) {
      homebrew.brews = packages;
    };

  # Virtualisation flag getter
  getVirtualisationFlag = {
    virtualisation ? {},
    modulesVirtualisation ? {},
    flagName,
    default ? false,
  }: let
    flagPath =
      if builtins.isList flagName
      then flagName
      else lib.splitString "." flagName;
    mergedVirtualisation = lib.recursiveUpdate modulesVirtualisation virtualisation;
  in
    lib.attrByPath flagPath default mergedVirtualisation;

  # System rebuild command generator
  systemRebuildCommand = system: {
    flakePath ? "~/.config/nix",
    hostName ? null,
    ...
  }:
    if isDarwin system
    then "sudo darwin-rebuild switch --flake ${flakePath}"
    else let
      hostSuffix =
        if hostName == null || hostName == ""
        then ""
        else "#${hostName}";
    in "sudo nixos-rebuild switch --flake ${flakePath}${hostSuffix}";
}
