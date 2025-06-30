{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Development tools (cross-platform)
    awscli2
    biome
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
    nodePackages_latest.pnpm
    nodePackages_latest.typescript
    nodePackages_latest.typescript-language-server
    nodePackages_latest.vscode-langservers-extracted
    pgcli
    pyright
    rustup
    solana-cli
    tree
    yaml-language-server
    yq
  ];

  imports = [
    ./apps/cursor
    ./apps/bat.nix
    ./apps/direnv.nix
    ./apps/fzf.nix
    ./apps/ripgrep.nix
    ./apps/zoxide.nix
    ./apps/helix.nix
  ];
}
