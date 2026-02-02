{ inputs }:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
  inherit (inputs)
    darwin
    home-manager
    sops-nix
    niri
    ironbar
    musnix
    solaar
    determinate
    nix-homebrew
    ;
  mac-app-util = inputs.mac-app-util or null;
  nix-flatpak = inputs.nix-flatpak or null;
  signal = inputs.signal or null;
  signal-ironbar = inputs.signal-ironbar or null;
  signal-notifications = inputs.signal-notifications or null;
  dms = inputs.dms or null;
  dms-plugin-registry = inputs.dms-plugin-registry or null;
  danksearch = inputs.danksearch or null;
  functionsLib = import ./functions.nix { inherit lib; };
  constants = import ./constants.nix;
  commonModules = [ ../modules/shared ];

  # Common specialArgs for both Darwin and NixOS
  mkCommonSpecialArgs =
    hostConfig: extraArgs:
    {
      inherit inputs constants;
      inherit (hostConfig)
        system
        username
        useremail
        hostname
        ;
      hostSystem = hostConfig.system;
    }
    // extraArgs;

  # Common nixpkgs config
  nixpkgsModule = hostConfig: {
    nixpkgs = {
      overlays = functionsLib.mkOverlays {
        inherit inputs;
        inherit (hostConfig) system;
      };
      config = functionsLib.mkPkgsConfig;
    };
  };

  # Common home-manager modules (Darwin subset)
  darwinHomeModules =
    lib.optionals (sops-nix != null) [ sops-nix.homeManagerModules.sops ]
    ++ lib.optionals (ironbar != null && ironbar ? homeManagerModules) [
      ironbar.homeManagerModules.default
    ]
    ++ lib.optionals (nix-flatpak != null) [ nix-flatpak.homeManagerModules.nix-flatpak ]
    # signal-nix removed from Darwin - GTK theme is Linux-only
    # ++ lib.optionals (signal != null) [ signal.homeManagerModules.default ]
    ++ lib.optionals (mac-app-util != null) [ mac-app-util.homeManagerModules.default ];

  # NixOS-specific home-manager modules (superset)
  nixosHomeModules =
    darwinHomeModules
    # signal-nix for NixOS only (GTK theme is Linux-only)
    ++ lib.optionals (signal != null) [ signal.homeManagerModules.default ]
    # Removed signal-notifications - only needed for signal-ironbar
    # ++ lib.optionals (signal-notifications != null) [ signal-notifications.homeManagerModules.default ]
    ++ lib.optionals (dms != null) [
      dms.homeModules.dank-material-shell
      dms.homeModules.niri
    ]
    ++ lib.optionals (dms-plugin-registry != null) [
      dms-plugin-registry.modules.default
    ]
    ++ lib.optionals (danksearch != null) [
      danksearch.homeModules.default
    ];

  # Common home-manager configuration
  mkHomeManagerModule = hostConfig: sharedModules: [
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        verbose = true;
        backupFileExtension = "hm-backup";
        extraSpecialArgs = functionsLib.mkHomeManagerExtraSpecialArgs {
          inherit inputs hostConfig;
          includeUserFields = true;
        };
        inherit sharedModules;
        users.${hostConfig.username} = import ../home;
      };
    }
    (
      { config, ... }:
      {
        home-manager.extraSpecialArgs.systemConfig = config;
      }
    )
  ];
in
{
  mkDarwinSystem =
    hostName: hostConfig:
    { homebrew-j178 }:
    (
      if darwin == null then
        throw "darwin input is required for mkDarwinSystem"
      else
        darwin.lib.darwinSystem
    )
      {
        inherit (hostConfig) system;
        specialArgs = mkCommonSpecialArgs hostConfig { };
        modules = [
          ../hosts/${hostName}/configuration.nix
          { config.host = hostConfig; }
          ../modules/darwin/default.nix
        ]
        ++ lib.optionals (determinate != null) [ determinate.darwinModules.default ]
        ++ lib.optionals (sops-nix != null) [ sops-nix.darwinModules.sops ]
        ++ lib.optionals (mac-app-util != null) [ mac-app-util.darwinModules.default ]
        ++ lib.optionals (nix-homebrew != null) [ nix-homebrew.darwinModules.nix-homebrew ]
        ++ [
          (nixpkgsModule hostConfig)
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = hostConfig.username;
              autoMigrate = true;
              taps."j178/homebrew-tap" = homebrew-j178;
              mutableTaps = false;
            };
          }
        ]
        ++ lib.optionals (home-manager != null) (
          [ home-manager.darwinModules.home-manager ] ++ mkHomeManagerModule hostConfig darwinHomeModules
        )
        ++ commonModules;
      };

  mkNixosSystem =
    hostName: hostConfig:
    { self }:
    nixpkgs.lib.nixosSystem {
      inherit (hostConfig) system;
      specialArgs = mkCommonSpecialArgs hostConfig {
        keysDirectory = "${self}/keys";
        inherit (inputs) nix-colorizer;
      };
      modules = [
        ../hosts/${hostName}/configuration.nix
        { config.host = hostConfig; }
        (nixpkgsModule hostConfig)
        ../modules/nixos/default.nix
      ]
      ++ lib.optionals (determinate != null) [ determinate.nixosModules.default ]
      ++ lib.optionals (sops-nix != null) [ sops-nix.nixosModules.sops ]
      ++ lib.optionals (niri != null) [ niri.nixosModules.niri ]
      ++ lib.optionals (musnix != null) [ musnix.nixosModules.musnix ]
      ++ lib.optionals (solaar != null) [ solaar.nixosModules.default ]
      ++ lib.optionals (dms != null) [
        dms.nixosModules.dank-material-shell
        dms.nixosModules.greeter
      ]
      ++ lib.optionals (inputs ? nix-topology && inputs.nix-topology != null) [
        inputs.nix-topology.nixosModules.default
      ]
      ++ lib.optionals (inputs ? vpn-confinement && inputs.vpn-confinement != null) [
        inputs.vpn-confinement.nixosModules.default
      ]
      ++ lib.optionals (signal != null) [ signal.nixosModules.default ]
      ++ lib.optionals (home-manager != null) (
        [ home-manager.nixosModules.home-manager ] ++ mkHomeManagerModule hostConfig nixosHomeModules
      )
      ++ commonModules;
    };
}
