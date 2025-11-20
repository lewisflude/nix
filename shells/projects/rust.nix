{
  pkgs,
  lib,
  ...
}:
let
  packageSets = import ../../lib/package-sets.nix {
    inherit pkgs;
  };
  featureBuilders = import ../../lib/feature-builders.nix {
    inherit lib packageSets;
  };
  commonTools = [
    pkgs.pre-commit
    pkgs.git
  ];
in
pkgs.mkShell {
  buildInputs =
    featureBuilders.mkShellPackages {
      cfg = {
        rust = true;
      };
      inherit pkgs;
    }
    ++ commonTools;
  shellHook = ''
    echo "?? Rust development environment loaded"
    echo "Rust version: $(rustc --version 2>/dev/null || echo 'Not installed - run: rustup install stable')"
    echo "Cargo version: $(cargo --version 2>/dev/null || echo 'Not installed')"
    echo ""
    echo "Available tools:"
    echo "  - rustc, cargo, rustfmt, clippy"
    echo "  - rust-analyzer (for LSP)"
    echo "  - cargo-watch, cargo-audit, cargo-edit"
    echo ""
    echo "?? Tip: Use 'direnv allow' in your project to auto-load this shell"
  '';
}
