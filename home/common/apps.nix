{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Development tools (cross-platform)
    awscli2
    bat
    biome
    black
    claude-code
    codex
    coreutils
    curl
    delta
    fd
    fzf
    gh
    helix
    htop
    http-server
    jq
    lazygit
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
    ripgrep
    rustup
    solana-cli
    tree
    wget
    yaml-language-server
    yq
    zellij
  ];

  # Simple program configurations
  programs.ripgrep.enable = true;

  imports = [
    ./apps/bat.nix
    ./apps/direnv.nix
    ./apps/fzf.nix
    ./apps/zoxide.nix
    ./apps/cursor
    ./apps/helix.nix
    ./apps/yazi.nix
  ];
}