{ lib, system, ... }:

{
  # Platform detection utilities
  isLinux = lib.hasInfix "linux" system;
  isDarwin = lib.hasInfix "darwin" system;
  isAarch64 = lib.hasInfix "aarch64" system;
  isX86_64 = lib.hasInfix "x86_64" system;

  # Conditional package inclusion helpers
  platformPackages = linuxPkgs: darwinPkgs: 
    (lib.optionals (lib.hasInfix "linux" system) linuxPkgs) ++
    (lib.optionals (lib.hasInfix "darwin" system) darwinPkgs);

  # Architecture-specific package selection
  archPackages = x86Pkgs: aarch64Pkgs:
    (lib.optionals (lib.hasInfix "x86_64" system) x86Pkgs) ++
    (lib.optionals (lib.hasInfix "aarch64" system) aarch64Pkgs);

  # Conditional module imports
  platformModules = linuxModules: darwinModules:
    (lib.optionals (lib.hasInfix "linux" system) linuxModules) ++
    (lib.optionals (lib.hasInfix "darwin" system) darwinModules);

  # Home directory path helper
  homeDir = username: if (lib.hasInfix "darwin" system) 
    then "/Users/${username}" 
    else "/home/${username}";

  # Config directory helper
  configDir = username: "${homeDir username}/.config";

  # System-specific service management
  enableSystemService = serviceName: lib.mkIf (lib.hasInfix "linux" system) {
    systemd.user.services.${serviceName}.enable = true;
  };

  # Homebrew package helper for Darwin
  brewPackages = packages: lib.mkIf (lib.hasInfix "darwin" system) {
    homebrew.brews = packages;
  };
}