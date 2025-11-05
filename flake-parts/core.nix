{
  inputs,
  self,
  withSystem,
  ...
}: let
  nixpkgs = inputs.nixpkgs or (throw "nixpkgs input is required");
  inherit (nixpkgs) lib;

  hostsConfig = import ../lib/hosts.nix {inherit lib;};
  inherit (hostsConfig) hosts;

  functionsLib = import ../lib/functions.nix {inherit lib;};
  validationLib = import ../lib/validation.nix {inherit lib;};

  systemBuilders = import ../lib/system-builders.nix {
    inherit inputs validationLib;
  };

  outputBuilders = import ../lib/output-builders.nix {
    inputs =
      inputs
      // {
        inherit self;
      };
    inherit hosts;
  };
in {
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  perSystem = {
    config,
    system,
    ...
  }: let
    # Configure pkgs with overlays for this system
    # Override pkgs via _module.args to apply overlays
    nixpkgs = inputs.nixpkgs or (throw "nixpkgs input is required");
    pkgsWithOverlays = import nixpkgs {
      inherit system;
      overlays = functionsLib.mkOverlays {inherit inputs system;};
      config = functionsLib.mkPkgsConfig;
    };

    # Import shells configuration
    # pog overlay is optional - only extend if available
    pogOverlay =
      if
        inputs ? pog
        && inputs.pog ? overlays
        && inputs.pog.overlays ? ${system}
        && inputs.pog.overlays.${system} ? default
      then inputs.pog.overlays.${system}.default
      else (_final: _prev: {});
    shellsConfig = import ../shells {
      pkgs = pkgsWithOverlays.extend pogOverlay;
      inherit (pkgsWithOverlays) lib;
      inherit system;
    };
  in {
    # Override pkgs that flake-parts provides
    _module.args.pkgs = pkgsWithOverlays;

    # Per-system formatter
    formatter = pkgsWithOverlays.nixfmt;

    # Per-system checks
    checks = outputBuilders.mkChecks.${system} or {};

    # Per-system dev shells
    devShells =
      shellsConfig.devShells
      // {
        default = pkgsWithOverlays.mkShell {
          shellHook = config.checks.pre-commit-check.shellHook or "";
          buildInputs =
            (config.checks.pre-commit-check.enabledPackages or [])
            ++ (with pkgsWithOverlays; [
              jq
              yq
              git
              gh
              direnv
              nix-direnv
              nix-update # Tool for updating package versions/hashes
            ]);
        };
      };

    # Per-system apps
    apps = let
      # Use the same pog overlay check as above
      pkgsWithPog = pkgsWithOverlays.extend pogOverlay;
      # Helper to create pog app
      # Scripts that need config-root: new-module, update-all
      # Scripts that don't: setup-cachix
      mkPogApp = script-name: let
        needsConfigRoot = lib.elem script-name [
          "new-module"
          "update-all"
        ];
        scriptArgs =
          if needsConfigRoot
          then {
            config-root = toString ../..;
          }
          else {
            # setup-cachix and others don't need config-root
          };
      in {
        type = "app";
        program = "${pkgsWithPog.callPackage ../pkgs/pog-scripts/${script-name}.nix scriptArgs}/bin/${script-name}";
      };
    in {
      # POG-powered CLI tools
      new-module = mkPogApp "new-module";
      setup-cachix = mkPogApp "setup-cachix";
      update-all = mkPogApp "update-all";
    };

    # Configure topology for systems that can build it (Linux only)
    topology.modules = lib.optionals (system == "x86_64-linux" || system == "aarch64-linux") [
      {
        # Inform topology of existing NixOS hosts
        inherit (self) nixosConfigurations;
      }
      # Add your topology definitions here (networks, connections, etc.)
      # Example:
      # {
      #   networks.home = {
      #     name = "Home Network";
      #     cidrv4 = "192.168.1.0/24";
      #   };
      # }
    ];
  };

  _module.args = {
    inherit
      hosts
      hostsConfig
      systemBuilders
      outputBuilders
      ;
  };

  flake = let
    # Build Darwin configurations using withSystem to access perSystem definitions
    # This follows flake-parts best practices: top-level configs should use withSystem
    # to access perSystem packages and other definitions
    darwinHosts = hostsConfig.getDarwinHosts hosts;
    darwinConfigurations =
      builtins.mapAttrs (
        hostName: hostConfig:
          withSystem hostConfig.system (
            {config, ...}:
              systemBuilders.mkDarwinSystem hostName hostConfig {
                inherit (inputs) homebrew-j178;
                # Use pkgs from perSystem instead of importing nixpkgs separately
                # This ensures consistency and follows flake-parts patterns
                perSystemPkgs = config.pkgs;
              }
          )
      )
      darwinHosts;

    # Build NixOS configurations using withSystem to access perSystem definitions
    nixosHosts = hostsConfig.getNixosHosts hosts;
    nixosConfigurations =
      builtins.mapAttrs (
        hostName: hostConfig:
          withSystem hostConfig.system (
            _:
              systemBuilders.mkNixosSystem hostName hostConfig {
                inherit self;
              }
          )
      )
      nixosHosts;

    # Build Home Manager configurations using withSystem to access perSystem definitions
    # Map over all hosts and use withSystem for each host's system
    homeConfigurations =
      builtins.mapAttrs (
        _hostName: hostConfig:
          withSystem hostConfig.system (
            {config, ...}:
              outputBuilders.mkHomeConfigurationForHost {
                inherit hostConfig;
                perSystemPkgs = config.pkgs;
              }
          )
      )
      hosts;
  in {
    inherit darwinConfigurations nixosConfigurations homeConfigurations;
    lib = functionsLib // validationLib;

    # Export overlays following flake-parts conventions
    # Overlays are defined at the top level (not under system attributes).
    # The system is determined from prev.stdenv.hostPlatform.system at evaluation time.
    # If an overlay needs perSystem config (e.g., config.packages), use withSystem pattern.
    # See: https://flake.parts/overlays.html
    overlays.default = final: prev:
    # Extract system from prev.stdenv.hostPlatform.system (flake-parts recommended pattern)
    # This allows the overlay to work with any system without being defined under a system attribute
      (import ../lib/overlay-builder.nix {
        inherit inputs;
        inherit (prev.stdenv.hostPlatform) system;
      })
      final
      prev;
  };
}
