{ lib
, system
, ...
}: rec {
  # Central version constants for consistency across the configuration
  versions = {
    nodejs = "nodejs_24";
    python = "python313";
    go = "go";
    rust = {
      package = "rustc";
      cargo = "cargo";
    };
  };

  # Helper to get versioned package
  getVersionedPackage = pkgs: packageName: lib.getAttr packageName pkgs;
  # Base platform detection
  isLinux = lib.hasInfix "linux" system;
  isDarwin = lib.hasInfix "darwin" system;
  ifLinux = value: lib.optionalAttrs isLinux value;
  ifDarwin = value: lib.optionalAttrs isDarwin value;
  isAarch64 = lib.hasInfix "aarch64" system;
  isX86_64 = lib.hasInfix "x86_64" system;

  # Combined platform checks
  isLinuxX86_64 = isLinux && isX86_64;
  isLinuxAarch64 = isLinux && isAarch64;
  isDarwinX86_64 = isDarwin && isX86_64;
  isDarwinAarch64 = isDarwin && isAarch64;

  # Conditional package inclusion helpers
  platformPackages = linuxPkgs: darwinPkgs: (lib.optionals isLinux linuxPkgs) ++ (lib.optionals isDarwin darwinPkgs);

  # Architecture-specific package selection
  archPackages = x86Pkgs: aarch64Pkgs: (lib.optionals isX86_64 x86Pkgs) ++ (lib.optionals isAarch64 aarch64Pkgs);

  # Conditional module imports
  platformModules = linuxModules: darwinModules:
    (lib.optionals isLinux linuxModules) ++ (lib.optionals isDarwin darwinModules);

  # System-specific paths
  homeDir = username:
    if isDarwin
    then "/Users/${username}"
    else "/home/${username}";
  configDir = username: "${homeDir username}/.config";
  dataDir = username:
    if isDarwin
    then "${homeDir username}/Library/Application Support"
    else "${homeDir username}/.local/share";
  cacheDir = username:
    if isDarwin
    then "${homeDir username}/Library/Caches"
    else "${homeDir username}/.cache";

  # System-specific service management
  enableSystemService = serviceName:
    lib.mkIf isLinux {
      systemd.user.services.${serviceName}.enable = true;
    };

  # Homebrew package helper for Darwin
  brewPackages = packages:
    lib.mkIf isDarwin {
      homebrew.brews = packages;
    };

  # Platform-specific configuration helpers
  platformConfig = linuxConfig: darwinConfig:
    if isLinux
    then linuxConfig
    else darwinConfig;

  # Root group helper (commonly used pattern)
  rootGroup =
    if isDarwin
    then "wheel"
    else "root";

  # Platform-specific package selection
  platformPackage = linuxPkg: darwinPkg:
    if isLinux
    then linuxPkg
    else darwinPkg;

  # Platform-specific state version helper
  platformStateVersion =
    if isDarwin
    then 6
    else "25.05";

  # Platform-specific system rebuild command
  systemRebuildCommand =
    if isDarwin
    then "sudo darwin-rebuild switch --flake ~/.config/nix"
    else "sudo nixos-rebuild switch --flake ~/.config/nix#jupiter";
}
