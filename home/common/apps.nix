{
  pkgs,
  ...
}:
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
    nodePackages.pnpm
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
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
    ./apps/yazi.nix
    ./apps/zoxide.nix
    ./apps/helix.nix
  ];
}
