# Development Shell - Common Development Tools
# Use this shell for general development work
# Access with: nix develop .#devShells.development
{ pkgs, ... }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Build tools
    cmake
    gnumake
    pkg-config

    # SSL/crypto libraries
    openssl
    libsecret
    libiconv

    # Version control
    git
    gh
    git-lfs

    # Rust toolchain management
    rustup

    # Nix tooling
    cachix
    nix-tree
    nix-du
    nix-update
    nix-prefetch-github

    # Language servers
    yaml-language-server

    # Database tools
    pgcli
  ];

  shellHook = ''
    echo "🔧 Development shell loaded"
    echo "Available tools: cmake, make, pkg-config, openssl, git, rustup, etc."
    echo ""
    echo "To use Rust:"
    echo "  rustup install stable"
    echo "  rustup default stable"
  '';
}
