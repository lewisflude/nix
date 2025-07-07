{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Development tools (cross-platform)
    awscli2
    claude-code
    codex
    coreutils
    delta
    gh
    htop
    http-server
    nodePackages_latest.pnpm
    nodePackages_latest.typescript
    nodePackages_latest.typescript-language-server
    nodePackages_latest.vscode-langservers-extracted
    pgcli
    rustup
    solana-cli
    tree
    yaml-language-server
    yq
    
    # Note: Language servers moved to development/language-tools.nix:
    # - nil (Nix LSP)
    # - nixfmt-rfc-style (Nix formatter)
    # - biome (JS/TS formatter)
    # - marksman (Markdown LSP)
    # - pyright (Python LSP)
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
