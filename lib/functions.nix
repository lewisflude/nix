{ lib }:
let
  # System detection helpers (pure functions that take system as parameter)
  # Defined first to avoid forward reference issues
  isLinux = system: lib.hasInfix "linux" system;
  isDarwin = system: lib.hasInfix "darwin" system;
  isAarch64 = system: lib.hasInfix "aarch64" system;
  isX86_64 = system: lib.hasInfix "x86_64" system;

  # Platform-specific value selectors
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

  # Platform-specific paths
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

  # Platform-specific constants
  rootGroup = system: if isDarwin system then "wheel" else "root";

  platformStateVersion = system: if isDarwin system then 6 else "25.05";

  # System service helpers
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

  # Virtualisation flag getter
  getVirtualisationFlag =
    {
      virtualisation ? { },
      modulesVirtualisation ? { },
      flagName,
      default ? false,
    }:
    let
      flagPath = if builtins.isList flagName then flagName else lib.splitString "." flagName;
      mergedVirtualisation = lib.recursiveUpdate modulesVirtualisation virtualisation;
    in
    lib.attrByPath flagPath default mergedVirtualisation;

  # System rebuild command generator
  # Uses nh for NixOS (recommended with Determinate Nix) and darwin-rebuild for macOS
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
        # nh handles sudo elevation internally, so no sudo prefix needed
        # Falls back to nixos-rebuild if nh is not available (though unlikely with programs.nh.enable)
      in
      "nh os switch ${flakePath}${hostSuffix}";

  # Helper to build Home Manager extraSpecialArgs
  # Reduces duplication between system-builders.nix and output-builders.nix
  mkHomeManagerExtraSpecialArgs =
    {
      inputs,
      hostConfig,
      virtualisationLib,
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
      modulesVirtualisation = virtualisationLib.mkModulesVirtualisationArgs {
        hostVirtualisation = hostConfig.features.virtualisation or { };
      };
    };

  # Version management (defined at top level for use in withSystem)
  versions = {
    nodejs = "nodejs"; # Default Node.js version from nixpkgs
    python = "python312"; # Python 3.12 from nixpkgs-python (via overlay) - better cache coverage
    go = "go";
    rust = {
      package = "rustc";
      cargo = "cargo";
    };
  };

  getVersionedPackage = pkgs: packageName: lib.getAttr packageName pkgs;

  functionsLib = {
    # Version management
    inherit versions getVersionedPackage;

    # Shared nixpkgs configuration
    # Use this instead of duplicating config blocks
    mkPkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
      allowBroken = true; # Allow broken packages (e.g., CUDA packages)
      allowUnsupportedSystem = false;
    };

    # Helper to get overlays list for a system
    # Consolidates overlay import pattern
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

    # Helper to create a system-bound version of all platform functions
    # Usage: platformLib = (import ./lib/functions.nix {inherit lib;}).withSystem system;
    withSystem = system: {
      inherit system;
      inherit versions;
      inherit getVersionedPackage;
      inherit getVirtualisationFlag;

      # System detection (bound to system)
      isLinux = isLinux system;
      isDarwin = isDarwin system;
      isAarch64 = isAarch64 system;
      isX86_64 = isX86_64 system;

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

    # Re-export system detection helpers for direct access
    inherit
      isLinux
      isDarwin
      isAarch64
      isX86_64
      ;

    # Platform-specific value selectors
    inherit
      ifLinux
      ifDarwin
      platformPackages
      archPackages
      platformModules
      platformConfig
      platformPackage
      ;

    # Platform-specific paths
    inherit
      homeDir
      configDir
      dataDir
      cacheDir
      ;

    # Platform-specific constants
    inherit rootGroup platformStateVersion;

    # System service helpers
    inherit enableSystemService brewPackages;

    # Virtualisation flag getter
    inherit getVirtualisationFlag;

    # System rebuild command generator
    inherit systemRebuildCommand;

    # Helper to build Home Manager extraSpecialArgs
    inherit mkHomeManagerExtraSpecialArgs;
  };
in
functionsLib
