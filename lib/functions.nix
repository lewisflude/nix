{ lib }:
let

  isLinux = system: lib.hasInfix "linux" system;
  isDarwin = system: lib.hasInfix "darwin" system;
  isAarch64 = system: lib.hasInfix "aarch64" system;
  isX86_64 = system: lib.hasInfix "x86_64" system;

  ifLinux = system: value: lib.optionalAttrs (isLinux system) value;
  ifDarwin = system: value: lib.optionalAttrs (isDarwin system) value;

  platformPackages =
    system: linuxPkgs: darwinPkgs:
    if isLinux system then
      linuxPkgs
    else if isDarwin system then
      darwinPkgs
    else
      [ ];

  archPackages =
    system: x86Pkgs: aarch64Pkgs:
    if isX86_64 system then
      x86Pkgs
    else if isAarch64 system then
      aarch64Pkgs
    else
      [ ];

  platformModules =
    system: linuxModules: darwinModules:
    if isLinux system then
      linuxModules
    else if isDarwin system then
      darwinModules
    else
      [ ];

  platformConfig =
    system: linuxConfig: darwinConfig:
    if isLinux system then linuxConfig else darwinConfig;

  platformPackage =
    system: linuxPkg: darwinPkg:
    if isLinux system then linuxPkg else darwinPkg;

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

  rootGroup = system: if isDarwin system then "wheel" else "root";

  platformStateVersion = system: if isDarwin system then 6 else "25.05";

  enableSystemService =
    system: serviceName:
    lib.mkIf (isLinux system) {
      systemd.user.services.${serviceName}.enable = true;
    };

  brewPackages =
    system: packages:
    lib.mkIf (isDarwin system) {
      homebrew.brews = packages;
    };

  systemRebuildCommand =
    system:
    {
      flakePath ? "~/.config/nix",
      hostName ? null,
      ...
    }:
    if isDarwin system then
      "sudo darwin-rebuild switch --flake ${flakePath}"
    else
      let
        hostSuffix = if hostName == null || hostName == "" then "" else "#${hostName}";
      in
      "nh os switch ${flakePath}${hostSuffix}";

  mkHomeManagerExtraSpecialArgs =
    {
      inputs,
      hostConfig,
      includeUserFields ? true,
    }:
    inputs
    // hostConfig
    // {
      inherit inputs;
      inherit (hostConfig) system;
      hostSystem = hostConfig.system;
      host = hostConfig;
    }
    // lib.optionalAttrs includeUserFields {
      inherit (hostConfig) username useremail hostname;
    }
    // {
      virtualisation = hostConfig.features.virtualisation or { };
    };

  versions = {
    nodejs = "nodejs";
    python = "python3";
    go = "go";
    rust = {
      package = "rustc";
      cargo = "cargo";
    };
  };

  getVersionedPackage = pkgs: packageName: lib.getAttr packageName pkgs;

  functionsLib = {

    inherit versions getVersionedPackage;

    mkPkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
      allowBroken = true;
      allowUnsupportedSystem = false;
    };

    mkOverlays =
      {
        inputs,
        system,
      }:
      lib.attrValues (
        import ../overlays {
          inherit inputs;
          inherit system;
        }
      );

    withSystem = system: {
      inherit system;
      inherit versions;
      inherit getVersionedPackage;

      isLinux = isLinux system;
      isDarwin = isDarwin system;
      isAarch64 = isAarch64 system;
      isX86_64 = isX86_64 system;

      ifLinux = ifLinux system;
      ifDarwin = ifDarwin system;
      platformPackages = platformPackages system;
      archPackages = archPackages system;
      platformModules = platformModules system;
      platformConfig = platformConfig system;
      platformPackage = platformPackage system;

      homeDir = homeDir system;
      configDir = configDir system;
      dataDir = dataDir system;
      cacheDir = cacheDir system;

      rootGroup = rootGroup system;
      platformStateVersion = platformStateVersion system;

      enableSystemService = enableSystemService system;
      brewPackages = brewPackages system;
      systemRebuildCommand = systemRebuildCommand system;
    };

    inherit
      isLinux
      isDarwin
      isAarch64
      isX86_64
      ;

    inherit
      ifLinux
      ifDarwin
      platformPackages
      archPackages
      platformModules
      platformConfig
      platformPackage
      ;

    inherit
      homeDir
      configDir
      dataDir
      cacheDir
      ;

    inherit rootGroup platformStateVersion;

    inherit enableSystemService brewPackages;

    inherit systemRebuildCommand;

    inherit mkHomeManagerExtraSpecialArgs;
  };
in
functionsLib
