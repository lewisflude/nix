{
  lib,
  system,
  ...
}: rec {
  versions = {
    nodejs = "nodejs_22";  # Latest LTS version available in nixpkgs
    python = "python313";
    go = "go";
    rust = {
      package = "rustc";
      cargo = "cargo";
    };
  };
  getVersionedPackage = pkgs: packageName: lib.getAttr packageName pkgs;
  isLinux = lib.hasInfix "linux" system;
  isDarwin = lib.hasInfix "darwin" system;
  ifLinux = value: lib.optionalAttrs isLinux value;
  ifDarwin = value: lib.optionalAttrs isDarwin value;
  isAarch64 = lib.hasInfix "aarch64" system;
  isX86_64 = lib.hasInfix "x86_64" system;
  isLinuxX86_64 = isLinux && isX86_64;
  isLinuxAarch64 = isLinux && isAarch64;
  isDarwinX86_64 = isDarwin && isX86_64;
  isDarwinAarch64 = isDarwin && isAarch64;
  platformPackages = linuxPkgs: darwinPkgs: (lib.optionals isLinux linuxPkgs) ++ (lib.optionals isDarwin darwinPkgs);
  archPackages = x86Pkgs: aarch64Pkgs: (lib.optionals isX86_64 x86Pkgs) ++ (lib.optionals isAarch64 aarch64Pkgs);
  platformModules = linuxModules: darwinModules:
    (lib.optionals isLinux linuxModules) ++ (lib.optionals isDarwin darwinModules);
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
  enableSystemService = serviceName:
    lib.mkIf isLinux {
      systemd.user.services.${serviceName}.enable = true;
    };
  brewPackages = packages:
    lib.mkIf isDarwin {
      homebrew.brews = packages;
    };
  platformConfig = linuxConfig: darwinConfig:
    if isLinux
    then linuxConfig
    else darwinConfig;
  rootGroup =
    if isDarwin
    then "wheel"
    else "root";
  platformPackage = linuxPkg: darwinPkg:
    if isLinux
    then linuxPkg
    else darwinPkg;
  platformStateVersion =
    if isDarwin
    then 6
    else "25.05";
  systemRebuildCommand =
    if isDarwin
    then "sudo darwin-rebuild switch --flake ~/.config/nix"
    else "sudo nixos-rebuild switch --flake ~/.config/nix#jupiter";

}
