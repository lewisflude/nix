{
  inputs,
  self,
  ...
}: let
  inherit (inputs.nixpkgs) lib;

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

  mkDarwinSystem = hostName: hostConfig:
    systemBuilders.mkDarwinSystem hostName hostConfig {
      inherit (inputs) homebrew-j178;
    };

  mkNixosSystem = hostName: hostConfig: systemBuilders.mkNixosSystem hostName hostConfig {inherit self;};
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
    pkgsWithOverlays = import inputs.nixpkgs {
      inherit system;
      overlays = functionsLib.mkOverlays {inherit inputs system;};
      config = functionsLib.mkPkgsConfig;
    };

    # Import shells configuration
    shellsConfig = import ../shells {
      pkgs = pkgsWithOverlays.extend inputs.pog.overlays.${system}.default;
      inherit (pkgsWithOverlays) lib;
      inherit system;
    };
  in {
    # Override pkgs that flake-parts provides
    _module.args.pkgs = pkgsWithOverlays;

    # Per-system formatter
    formatter = pkgsWithOverlays.alejandra;

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
      # Helper to create pog app
      mkPogApp = script-name: {
        type = "app";
        program = "${
          import ../pkgs/pog-scripts/${script-name}.nix {
            pkgs = pkgsWithOverlays.extend inputs.pog.overlays.${system}.default;
            inherit (pkgsWithOverlays.extend inputs.pog.overlays.${system}.default) pog;
            config-root = toString ../.;
          }
        }/bin/${script-name}";
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

  flake = {
    darwinConfigurations = builtins.mapAttrs mkDarwinSystem (hostsConfig.getDarwinHosts hosts);

    nixosConfigurations = builtins.mapAttrs mkNixosSystem (hostsConfig.getNixosHosts hosts);

    homeConfigurations = outputBuilders.mkHomeConfigurations;

    lib = functionsLib // validationLib;
  };
}
