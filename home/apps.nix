{ pkgs, ... }:
{
  home.packages = with pkgs; [
    anchor
    awscli2
    bat
    betterdisplay
    biome
    black
    claude-code
    codex
    coreutils
    curl
    delta
    fd
    firefox-devedition
    fzf
    gh
    helix
    htop
    http-server
    insomnia
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
    pgadmin4
    pgcli
    playwright
    pyright
    raycast
    ripgrep
    rustup
    slack
    solana-cli
    tableplus
    tree
    wget
    yaml-language-server
    yq
    zellij
    dockutil
  ];

  # Simple program configurations
  programs.ripgrep.enable = true;

  imports = [
    ./apps/bat.nix
    ./apps/direnv.nix
    ./apps/fzf.nix
    ./apps/zoxide.nix
    ../modules/apps/cursor
    ./apps/helix.nix
    ./apps/yazi.nix
  ];

  # Enable Cursor editor via the new module
  programs.cursor.enable = true;
}
