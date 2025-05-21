{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Development Tools & IDEs
    code-cursor # AI-assisted code editor based on VS Code
    vscode
    helix
    awscli2

    # Programming Languages & Runtimes
    nodejs_22
    nodePackages.pnpm
    nodePackages.typescript

    # Language Servers & Linters
    nil
    nodePackages.typescript-language-server
    biome
    yaml-language-server
    marksman
    rust-analyzer
    pyright
    nodePackages.vscode-langservers-extracted # JSON language server
    black
    rustfmt
    nixpkgs-fmt

    # Development Environment Tools
    direnv
    nix-direnv
    nixfmt-classic

    # Version Control & Git Tools
    git
    gh
    lazygit
    delta

    # CLI Utilities & System Tools
    ripgrep
    fd
    fzf
    zellij
    coreutils
    curl
    htop
    tree
    wget
    bat # Better cat
    jq # JSON processor
    yq # YAML processor

    # Testing & Development Tools
    playwright
    http-server # Alternative to live-server
  ];
  imports = [
    ./apps/bat.nix
    ./apps/direnv.nix
    ./apps/fzf.nix
    ./apps/ripgrep.nix
    ./apps/zoxide.nix
    ./apps/cursor.nix
    ./apps/helix.nix
    ./apps/yazi.nix
    ./apps/firefox.nix
  ];
}
