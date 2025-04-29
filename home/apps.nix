{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
    # Development Tools & IDEs
    code-cursor # AI-assisted code editor based on VS Code
    vscode
    helix

    # Programming Languages & Runtimes
    nodejs_20
    nodePackages.pnpm
    nodePackages.typescript

    # Language Servers & Linters
    nodePackages.typescript-language-server
    nodePackages.prettier
    nodePackages.eslint
    nodePackages.stylelint

    # Development Environment Tools
    direnv
    nix-direnv
    nixfmt-classic

    # Version Control & Git Tools
    git
    gh # GitHub CLI
    lazygit
    delta # Better git diff

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
    ./apps/vscode.nix
    ./apps/helix.nix
    ./apps/yazi.nix
  ];
}
