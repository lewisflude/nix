{
  config,
  inputs,
  functionsLib,
  ...
}:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
in
{
  perSystem =
    { system, ... }:
    let
      # Get pkgs and pkgsWithPog from module args
      # These are set by per-system/pkgs.nix and per-system/pog-overlay.nix respectively
      # Use fallback to direct import if needed
      pkgs =
        config._module.args.pkgs or (import nixpkgs {
          inherit system;
          overlays = functionsLib.mkOverlays { inherit inputs system; };
          config = functionsLib.mkPkgsConfig;
        });
      # Get pog overlay if available
      getPogOverlay =
        if
          inputs ? pog
          && inputs.pog ? overlays
          && inputs.pog.overlays ? ${system}
          && inputs.pog.overlays.${system} ? default
        then
          inputs.pog.overlays.${system}.default
        else
          (_final: _prev: { });
      # Create pkgsWithPog by extending pkgs with pog overlay
      pkgsWithPog = config._module.args.pkgsWithPog or (pkgs.extend getPogOverlay);

      shellsConfig = import ../../shells {
        pkgs = pkgsWithPog;
        inherit (pkgs) lib;
        inherit system;
      };
    in
    {
      # Development shells for this system
      devShells = shellsConfig.devShells // {
        # Default dev shell with pre-commit hooks
        default = pkgs.mkShell {
          shellHook = config.checks.pre-commit-check.shellHook or "";
          buildInputs = (config.checks.pre-commit-check.enabledPackages or [ ]) ++ [
            pkgs.jq
            pkgs.yq
            pkgs.git
            pkgs.gh
            pkgs.direnv
            pkgs.nix-direnv
            pkgs.nix-update
            pkgs.cocogitto
            pkgs.git-cliff
            pkgs.vulnix # Vulnerability scanner for Nix packages
            inputs.pre-commit-hooks.packages.${system}.pre-commit
          ];
        };
      };
    };
}
