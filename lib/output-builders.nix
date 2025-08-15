# Output builder functions to simplify flake outputs generation
{
  inputs,
  hosts,
}: let
  inherit (inputs) nixpkgs pre-commit-hooks home-manager;
  inherit
    (builtins)
    mapAttrs
    attrValues
    listToAttrs
    map
    ;

  systems = builtins.attrValues (builtins.mapAttrs (_name: host: host.system) hosts);
in {
  # Generate formatter outputs for all systems
  mkFormatters = nixpkgs.lib.genAttrs systems (system: nixpkgs.legacyPackages.${system}.alejandra);

  # Generate pre-commit checks for all systems
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

  # Generate development shells for all host systems
  mkDevShells = builtins.listToAttrs (
    builtins.map (hostConfig: {
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
    }) (builtins.attrValues hosts)
  );

  # Generate Home Manager configurations
  mkHomeConfigurations =
    builtins.mapAttrs (
      _name: hostConfig: let
        pkgs = import nixpkgs {
          inherit (hostConfig) system;
        };
      in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = inputs // hostConfig;
          modules = [
            ../home
            inputs.catppuccin.homeModules.catppuccin
          ];
        }
    )
    hosts;
}
