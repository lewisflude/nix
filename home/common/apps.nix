{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Development tools (cross-platform)
    awscli2
    biome
    black
    claude-code
    codex
    coreutils
    delta
    gh
    htop
    http-server
    marksman
    nil
    nixfmt-rfc-style
    nodejs_22
    nodePackages.pnpm
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    pgcli
    playwright
    pyright
    rustup
    solana-cli
    tree
    yaml-language-server
    yq
  ];

  imports = [
    ./apps/cursor
    ./apps/helix.nix
    ./apps/yazi.nix
  ];
}
