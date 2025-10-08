# Output builder functions to simplify flake outputs generation
{ inputs
, hosts
,
}:
let
  inherit (inputs) nixpkgs pre-commit-hooks home-manager;

  systems = builtins.attrValues (builtins.mapAttrs (_name: host: host.system) hosts);
in
{
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
    builtins.map
      (hostConfig: {
        name = hostConfig.system;
        value =
          let
            pkgs = nixpkgs.legacyPackages.${hostConfig.system};
            shellsConfig = import ../shells {
              inherit pkgs;
              inherit (pkgs) lib;
              inherit (hostConfig) system;
            };
          in
          shellsConfig.devShells
          // {
            default =
              let
                preCommitCheck = inputs.self.checks.${hostConfig.system}.pre-commit-check or { };
              in
              pkgs.mkShell {
                shellHook = preCommitCheck.shellHook or "";
                buildInputs =
                  (preCommitCheck.enabledPackages or [ ])
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

  # Generate Home Manager configurations
  mkHomeConfigurations =
    builtins.mapAttrs
      (
        _name: hostConfig:
          let
            # Import nixpkgs with the same overlays as the system configuration
            pkgs = import nixpkgs {
              inherit (hostConfig) system;
              config = {
                allowUnfree = true;
                allowUnsupportedSystem = false;
              };
              overlays =
                [
                  # Apply the same overlays as the system configuration
                  (import ../overlays/cursor.nix)
                  (import ../overlays/npm-packages.nix)
                  inputs.yazi.overlays.default
                  inputs.niri.overlays.niri
                  (_: _: { waybar-git = inputs.waybar.packages.${hostConfig.system}.waybar; })
                  inputs.nur.overlays.default
                  inputs.nh.overlays.default
                  (final: _prev: {
                    inherit (inputs.swww.packages.${final.system}) swww;
                  })
                ]
                ++ (
                  if hostConfig.system == "aarch64-darwin" || hostConfig.system == "x86_64-darwin"
                  then [
                    # Darwin-specific overlays
                    (_: _: {
                      ghostty = inputs.ghostty.packages.${hostConfig.system}.default.override {
                        optimize = "ReleaseFast";
                        enableX11 = true;
                        enableWayland = true;
                      };
                    })
                  ]
                  else [ ]
                )
                ++ (
                  if inputs ? nvidia-patch
                  then [
                    inputs.nvidia-patch.overlays.default
                  ]
                  else [ ]
                );
            };
          in
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = inputs // hostConfig;
            modules = [
              ../home
              inputs.catppuccin.homeModules.catppuccin
              inputs.sops-nix.homeManagerModules.sops
              { _module.args = { inherit inputs; }; }
            ];
          }
      )
      hosts;
}
