# Per-system development shells
# Dendritic pattern: Provides dev shells for each system
{
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (inputs) nixpkgs;
  shared = import ../_shared.nix { inherit lib inputs; };
in
{
  perSystem =
    { system, ... }:
    let
      # Get pkgs from module args (set by per-system/pkgs.nix)
      pkgs =
        config._module.args.pkgs or (import nixpkgs {
          inherit system;
          overlays = shared.overlaysList system;
          config = shared.myLib.mkPkgsConfig;
        });
    in
    {
      # Default dev shell with pre-commit hooks and common tools
      devShells.default = pkgs.mkShell {
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
          pkgs.vulnix
          inputs.pre-commit-hooks.packages.${system}.pre-commit
        ];
      };
    };
}
