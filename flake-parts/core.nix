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
  cacheLib = import ../lib/cache.nix {inherit lib;};

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
      overlays = lib.attrValues (
        import ../overlays {
          inherit inputs;
          inherit system;
        }
      );
      config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
      };
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
    checks = {
      pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          # Nix formatting and linting
          alejandra.enable = true;
          deadnix.enable = true;
          statix.enable = true;

          # Conventional commits enforcement
          commitizen.enable = true;

          # General code quality
          trailing-whitespace = {
            enable = true;
            entry = "${pkgsWithOverlays.python3Packages.pre-commit-hooks}/bin/trailing-whitespace-fixer";
            types = ["text"];
          };
          end-of-file-fixer = {
            enable = true;
            entry = "${pkgsWithOverlays.python3Packages.pre-commit-hooks}/bin/end-of-file-fixer";
            types = ["text"];
          };
          mixed-line-ending = {
            enable = true;
            entry = "${pkgsWithOverlays.python3Packages.pre-commit-hooks}/bin/mixed-line-ending";
            types = ["text"];
          };

          # YAML validation
          check-yaml = {
            enable = true;
            entry = "${pkgsWithOverlays.python3Packages.pre-commit-hooks}/bin/check-yaml";
            types = ["yaml"];
            excludes = ["secrets/.*\\.yaml$"];
          };

          # Markdown formatting
          markdownlint = {
            enable = true;
            entry = "${pkgsWithOverlays.markdownlint-cli}/bin/markdownlint --fix";
            types = ["markdown"];
          };
        };
      };

      # nixosTests-mcp = import ../tests/integration/mcp.nix {
      #   inherit pkgs;
      #   lib = lib;
      #   inputs = inputs;
      # };
    };

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

    lib = functionsLib // validationLib // cacheLib;
  };
}
