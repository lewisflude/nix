{ inputs }:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;

  inherit (inputs) darwin;
  inherit (inputs) home-manager;
  mac-app-util = inputs.mac-app-util or null;
  inherit (inputs) nix-homebrew;
  inherit (inputs) sops-nix;
  mcp-home-manager = inputs.mcp-home-manager or null;

  inherit (inputs) niri;
  inherit (inputs) ironbar;
  inherit (inputs) musnix;
  inherit (inputs) solaar;
  inherit (inputs) determinate;
  nix-flatpak = inputs.nix-flatpak or null;
  signal = inputs.signal or null;

  functionsLib = import ./functions.nix { inherit lib; };

  # Shared resources (eliminates fragile relative imports)
  constants = import ../lib/constants.nix;
  # Note: palette and themeLib are now provided by Signal flake via _module.args
  # as signalPalette and signalLib

  commonModules = [
    ../modules/shared
  ];

  # Helper: Conditionally include a module if input exists
  optionalModule = cond: module: lib.optionals cond [ module ];

  # Helper: Build a list of optional Darwin integration modules
  # Follows flake-parts pattern: group related modules together
  mkDarwinIntegrationModules =
    attrs:
    let
      inherit (attrs) determinate;
      sops-nix = attrs."sops-nix" or null;
      home-manager = attrs."home-manager" or null;
      mac-app-util = attrs."mac-app-util" or null;
      nix-homebrew = attrs."nix-homebrew" or null;
    in
    # Core integration modules (always checked)
    optionalModule (determinate != null) determinate.darwinModules.default
    ++ optionalModule (home-manager != null) home-manager.darwinModules.home-manager
    ++ optionalModule (sops-nix != null) sops-nix.darwinModules.sops
    # Darwin-specific integrations
    # mac-app-util: Creates trampoline launchers for Nix-installed .app bundles,
    # making them searchable in Spotlight and allowing Dock pinning across updates.
    # See: modules/darwin/mac-app-util.nix
    ++ optionalModule (mac-app-util != null) mac-app-util.darwinModules.default
    ++ optionalModule (nix-homebrew != null) nix-homebrew.darwinModules.nix-homebrew;

  # Helper: Build a list of optional NixOS integration modules
  # Follows flake-parts pattern: group related modules together
  mkNixosIntegrationModules =
    attrs:
    let
      inherit (attrs) determinate;
      sops-nix = attrs."sops-nix" or null;
      inherit (attrs) niri;
      inherit (attrs) musnix;
      inherit (attrs) solaar;

      nix-topology = attrs."nix-topology" or null;
      vpn-confinement = attrs."vpn-confinement" or null;
      nixpkgs-xr = attrs."nixpkgs-xr" or null;
    in
    # Core integration modules
    optionalModule (determinate != null) determinate.nixosModules.default
    ++ optionalModule (sops-nix != null) sops-nix.nixosModules.sops
    # NixOS-specific integrations
    ++ optionalModule (niri != null) niri.nixosModules.niri
    ++ optionalModule (musnix != null) musnix.nixosModules.musnix
    ++ optionalModule (solaar != null) solaar.nixosModules.default
    ++ optionalModule (nix-topology != null) nix-topology.nixosModules.default
    ++ optionalModule (vpn-confinement != null) vpn-confinement.nixosModules.default
    # VR/XR support (provides nixpkgs-xr packages + Cachix cache configuration)
    ++ optionalModule (nixpkgs-xr != null) nixpkgs-xr.nixosModules.nixpkgs-xr;

  mkHomeManagerConfig =
    {
      hostConfig,
      extraSharedModules ? [ ],
    }:
    {
      # useGlobalPkgs=true shares system packages (more efficient, consistent overlays)
      useGlobalPkgs = true;
      useUserPackages = true;
      verbose = true;
      backupFileExtension = "backup";
      extraSpecialArgs = functionsLib.mkHomeManagerExtraSpecialArgs {
        inherit inputs hostConfig;
        includeUserFields = true;
      };
      sharedModules =
        optionalModule (sops-nix != null) sops-nix.homeManagerModules.sops
        ++ optionalModule (mcp-home-manager != null) mcp-home-manager.homeManagerModules.default
        ++ optionalModule (
          ironbar != null && ironbar ? homeManagerModules
        ) ironbar.homeManagerModules.default
        ++ optionalModule (nix-flatpak != null) nix-flatpak.homeManagerModules.nix-flatpak
        ++ optionalModule (signal != null) signal.homeManagerModules.default
        ++ extraSharedModules;
      users.${hostConfig.username} = import ../home;
    };
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

        specialArgs = {
          inherit inputs;
          inherit (hostConfig) system;
          hostSystem = hostConfig.system;
          inherit (hostConfig) username;
          inherit (hostConfig) useremail;
          inherit (hostConfig) hostname;
          # Shared resources
          inherit constants;
          # Note: palette and themeLib provided by Signal flake
        };

        # Module list follows flake-parts best practices:
        # 1. Host configuration first
        # 2. Core system modules
        # 3. Integration modules (conditionally)
        # 4. System-specific configuration
        # 5. Common modules last
        modules = [
          # Host-specific configuration
          ../hosts/${hostName}/configuration.nix
          {
            config.host = hostConfig;
          }
          # Platform-specific modules
          ../modules/darwin/default.nix
        ]
        # Integration modules (determinate, home-manager, sops-nix, etc.)
        ++ mkDarwinIntegrationModules {
          inherit
            determinate
            sops-nix
            home-manager
            mac-app-util
            nix-homebrew
            ;
        }
        # System configuration modules
        ++ [
          {
            nixpkgs = {
              overlays = functionsLib.mkOverlays {
                inherit inputs;
                inherit (hostConfig) system;
              };
              config = functionsLib.mkPkgsConfig;
            };
          }
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
          {
            home-manager = mkHomeManagerConfig {
              inherit hostConfig;
              # mac-app-util home-manager module: Enables app launcher support
              # for user-specific packages installed via home-manager
              extraSharedModules = optionalModule (mac-app-util != null) mac-app-util.homeManagerModules.default;
            };
          }
          (
            { config, ... }:
            {
              home-manager.extraSpecialArgs.systemConfig = config;
            }
          )
        ]
        # Common modules (shared between platforms)
        ++ commonModules;
      };

  mkNixosSystem =
    hostName: hostConfig:
    { self }:
    nixpkgs.lib.nixosSystem {
      inherit (hostConfig) system;

      specialArgs = {
        inherit inputs;
        inherit (hostConfig) system;
        hostSystem = hostConfig.system;
        inherit (hostConfig) username;
        inherit (hostConfig) useremail;
        inherit (hostConfig) hostname;
        keysDirectory = "${self}/keys";
        inherit (inputs) nix-colorizer;
        # Shared resources
        inherit constants;
        # Note: palette and themeLib provided by Signal flake
      };

      # Module list follows flake-parts best practices:
      # 1. Host configuration first
      # 2. Core system modules
      # 3. Integration modules (conditionally)
      # 4. System-specific configuration
      # 5. Common modules last
      modules = [
        # Host-specific configuration
        ../hosts/${hostName}/configuration.nix
        {
          config.host = hostConfig;
        }
        # Nixpkgs configuration (overlays, config)
        {
          nixpkgs = {
            overlays = functionsLib.mkOverlays {
              inherit inputs;
              inherit (hostConfig) system;
            };
            config = functionsLib.mkPkgsConfig;
          };
        }
        # Platform-specific modules
        ../modules/nixos/default.nix
      ]
      # Integration modules (determinate, sops-nix, niri, etc.)
      ++ mkNixosIntegrationModules {
        inherit
          determinate
          sops-nix
          niri
          musnix
          solaar

          ;
        inherit (inputs) nix-topology;
        inherit (inputs) vpn-confinement;
        inherit (inputs) nixpkgs-xr;
        isLinux = hostConfig.system == "x86_64-linux" || hostConfig.system == "aarch64-linux";
      }
      ++ optionalModule (home-manager != null) home-manager.nixosModules.home-manager
      # Home Manager configuration
      ++ [
        {
          home-manager = mkHomeManagerConfig { inherit hostConfig; };
        }
        (
          { config, ... }:
          {
            home-manager.extraSpecialArgs.systemConfig = config;
          }
        )
      ]
      # Common modules (shared between platforms)
      ++ commonModules;
    };
}
