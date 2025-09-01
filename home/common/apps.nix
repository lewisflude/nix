{pkgs, ...}: {
  home.packages = with pkgs; [
    # Development tools (cross-platform)
    awscli2
    claude-code
    codex
    gemini-cli
    coreutils
    delta
    htop
    btop
    pgcli
    rustup
    # solana-cli  # Temporarily disabled due to compilation errors
    tree
    yaml-language-server

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
    ./apps/obsidian.nix
  ];
}
