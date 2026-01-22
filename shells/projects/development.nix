{ pkgs, ... }:
pkgs.mkShell {
  buildInputs = [

    pkgs.cmake
    pkgs.gnumake
    pkgs.pkg-config

    pkgs.openssl
    pkgs.libsecret
    pkgs.libiconv

    pkgs.git
    pkgs.gh
    pkgs.git-lfs

    pkgs.rustup

    pkgs.cachix
    pkgs.nix-tree
    pkgs.nix-du
    pkgs.nix-update
    pkgs.nix-prefetch-github

    pkgs.yaml-language-server

    pkgs.pgcli
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
