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
        alejandra.enable = true;
        deadnix.enable = true;
        statix.enable = true;
      };
    };

    # nixosTests-mcp = import ../tests/integration/mcp.nix {
    #   inherit pkgs;
    #   lib = nixpkgs.lib;
    #   inputs = inputs;
    # };
  });
  mkDevShells = let
    hostsBySystem = nixpkgs.lib.groupBy (hostConfig: hostConfig.system) (builtins.attrValues hosts);
  in
    builtins.mapAttrs (
      system: _hostGroup: let
        pkgs = nixpkgs.legacyPackages.${system};
        shellsConfig = import ../shells {
          inherit pkgs;
          inherit (pkgs) lib;
          inherit system;
        };
        preCommitCheck = inputs.self.checks.${system}.pre-commit-check or {};
      in
        shellsConfig.devShells
        // {
          default = pkgs.mkShell {
            shellHook = preCommitCheck.shellHook or "";
            buildInputs =
              (preCommitCheck.enabledPackages or [])
              ++ (with pkgs; [
                jq
                yq
                git
                gh
                direnv
                nix-direnv
              ]);
          };
        }
    )
    hostsBySystem;
  mkHomeConfigurations =
    builtins.mapAttrs (
      _name: hostConfig: let
        pkgs = import nixpkgs {
          inherit (hostConfig) system;
          config = {
            allowUnfree = true;
            allowUnfreePredicate = _: true;
            allowUnsupportedSystem = false;
            permittedInsecurePackages = [
              "mbedtls-2.28.10"
            ];
          };
          overlays = nixpkgs.lib.attrValues (
            import ../overlays {
              inherit inputs;
              inherit (hostConfig) system;
            }
          );
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
