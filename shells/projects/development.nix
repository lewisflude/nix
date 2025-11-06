{ pkgs, ... }:
pkgs.mkShell {
  buildInputs = with pkgs; [

    cmake
    gnumake
    pkg-config

    openssl
    libsecret
    libiconv

    git
    gh
    git-lfs

    rustup

    cachix
    nix-tree
    nix-du
    nix-update
    nix-prefetch-github

    yaml-language-server

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
