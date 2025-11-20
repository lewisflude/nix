{
  pkgs,
  lib,
  ...
}:
let
  # platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
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
        python = true;
      };
      inherit pkgs;
    }
    ++ commonTools;
  shellHook = ''
    echo "?? Python development environment loaded"
    echo "Python version: $(python --version 2>/dev/null || echo 'Not available')"
    echo ""
    echo "Available tools:"
    echo "  - Python $(python --version 2>/dev/null | cut -d' ' -f2 || echo 'N/A')"
    echo "  - pip, virtualenv, black"
    echo "  - ruff (linter), pyright (type checker)"
    echo "  - poetry (dependency management)"
    echo ""
    echo "?? Tip: Use 'direnv allow' in your project to auto-load this shell"
    echo "?? Tip: Create virtualenv with 'python -m venv .venv'"
  '';
}
