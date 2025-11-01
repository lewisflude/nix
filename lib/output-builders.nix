{
  inputs,
  hosts,
}: let
  inherit (inputs) nixpkgs pre-commit-hooks home-manager;
  virtualisationLib = import ./virtualisation.nix {inherit (nixpkgs) lib;};
  systems = builtins.attrValues (builtins.mapAttrs (_name: host: host.system) hosts);
in {
  mkFormatters = nixpkgs.lib.genAttrs systems (system: nixpkgs.legacyPackages.${system}.alejandra);
  mkChecks = nixpkgs.lib.genAttrs systems (system: {
    pre-commit-check = pre-commit-hooks.lib.${system}.run {
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
          entry = "${
            nixpkgs.legacyPackages.${system}.python3Packages.pre-commit-hooks
          }/bin/trailing-whitespace-fixer";
          types = ["text"];
        };
        end-of-file-fixer = {
          enable = true;
          entry = "${
            nixpkgs.legacyPackages.${system}.python3Packages.pre-commit-hooks
          }/bin/end-of-file-fixer";
          types = ["text"];
        };
        mixed-line-ending = {
          enable = true;
          entry = "${
            nixpkgs.legacyPackages.${system}.python3Packages.pre-commit-hooks
          }/bin/mixed-line-ending";
          types = ["text"];
        };

        # YAML validation
        check-yaml = {
          enable = true;
          entry = "${nixpkgs.legacyPackages.${system}.python3Packages.pre-commit-hooks}/bin/check-yaml";
          types = ["yaml"];
          excludes = ["secrets/.*\\.yaml$"];
        };

        # Markdown formatting
        markdownlint = {
          enable = true;
          entry = "${nixpkgs.legacyPackages.${system}.markdownlint-cli}/bin/markdownlint --fix";
          types = ["markdown"];
        };
      };
    };

    # nixosTests-mcp = import ../tests/integration/mcp.nix {
    #   inherit pkgs;
    #   lib = nixpkgs.lib;
    #   inputs = inputs;
    # };
  });
  mkHomeConfigurations =
    builtins.mapAttrs (
      _name: hostConfig: let
        functionsLib = import ./functions.nix {inherit (nixpkgs) lib;};
        pkgs = import nixpkgs {
          inherit (hostConfig) system;
          config = functionsLib.mkPkgsConfig;
          overlays = functionsLib.mkOverlays {
            inherit inputs;
            system = hostConfig.system;
          };
        };
      in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs =
            inputs
            // hostConfig
            // {
              host = hostConfig;
              hostSystem = hostConfig.system;
              modulesVirtualisation = virtualisationLib.mkModulesVirtualisationArgs {
                hostVirtualisation = hostConfig.virtualisation or {};
              };
            };
          modules = [
            ../home
            inputs.niri.homeModules.niri
            inputs.sops-nix.homeManagerModules.sops
            inputs.catppuccin.homeModules.catppuccin
            {_module.args = {inherit inputs;};}
          ];
        }
    )
    hosts;
}
