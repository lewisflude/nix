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
  });
  mkDevShells = builtins.listToAttrs (
    builtins.map
    (hostConfig: {
      name = hostConfig.system;
      value = let
        pkgs = nixpkgs.legacyPackages.${hostConfig.system};
        shellsConfig = import ../shells {
          inherit pkgs;
          inherit (pkgs) lib;
          inherit (hostConfig) system;
        };
      in
        shellsConfig.devShells
        // {
          default = let
            preCommitCheck = inputs.self.checks.${hostConfig.system}.pre-commit-check or {};
          in
            pkgs.mkShell {
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
        };
    })
    (builtins.attrValues hosts)
  );
  mkHomeConfigurations =
    builtins.mapAttrs
    (
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
          overlays = import ../overlays {
            inherit inputs;
            inherit (hostConfig) system;
          };
        };
      in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs =
            inputs
            // hostConfig
            // {
              modulesVirtualisation = virtualisationLib.mkModulesVirtualisationArgs {
                hostVirtualisation = hostConfig.virtualisation or {};
              };
            };
          modules = [
            ../home
            inputs.catppuccin.homeModules.catppuccin
            inputs.niri.homeModules.niri
            inputs.sops-nix.homeManagerModules.sops
            {_module.args = {inherit inputs;};}
          ];
        }
    )
    hosts;
}
