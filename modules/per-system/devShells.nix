# Per-system development shells
# Dendritic pattern: Provides dev shells for each system
_: {
  perSystem =
    { pkgs, config, ... }:
    {
      # Default dev shell with pre-commit hooks and common tools
      devShells.default = pkgs.mkShell {
        # git-hooks' devShell carries the hook packages and installs the hooks.
        inputsFrom = [ config.pre-commit.devShell ];
        packages = [
          pkgs.jq
          pkgs.yq
          pkgs.git
          pkgs.gh
          pkgs.direnv
          pkgs.nix-direnv
          pkgs.nix-update
          # Parallel `nix flake check` replacement: evaluates and builds host
          # closures concurrently and streams per-derivation failures.
          pkgs.nix-fast-build
          # Batch nixf-tidy: the semantic analysis nixd already runs in the
          # editor, over the whole tree. Catches scope errors statix/deadnix miss.
          pkgs.nixf-diagnose
          pkgs.cocogitto
          pkgs.git-cliff
          pkgs.vulnix
        ];
      };
    };
}
