# Per-system development shells
# Dendritic pattern: Provides dev shells for each system
{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    {
      # Default dev shell with pre-commit hooks and common tools
      devShells.default = pkgs.mkShell {
        shellHook = config.pre-commit.settings.shellHook or "";
        buildInputs = (config.pre-commit.settings.enabledPackages or [ ]) ++ [
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
        ];
      };
    };
}
