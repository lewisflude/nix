{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
  packageSets = import ../../lib/package-sets.nix {
    inherit pkgs;
    inherit (platformLib) versions;
  };
  featureBuilders = import ../../lib/feature-builders.nix {
    inherit lib packageSets;
  };
  commonTools = with pkgs; [
    pre-commit
    git
  ];
in
pkgs.mkShell {
  buildInputs =
    featureBuilders.mkShellPackages {
      cfg = {
        node = true;
      };
      inherit pkgs;
      inherit (platformLib) versions;
    }
    ++ commonTools;
  shellHook = ''
    echo "?? Node.js development environment loaded"
    echo "Node version: $(node --version 2>/dev/null || echo 'Not available')"
    echo "pnpm version: $(pnpm --version 2>/dev/null || echo 'Not available')"
    echo "TypeScript version: $(tsc --version 2>/dev/null || echo 'Not available')"
    echo ""
    echo "Available tools:"
    echo "  - Node.js $(node --version 2>/dev/null | cut -d'v' -f2 || echo 'N/A')"
    echo "  - pnpm (package manager)"
    echo "  - TypeScript (type checker)"
    echo ""
    echo "?? Tip: Use 'direnv allow' in your project to auto-load this shell"
    echo "?? Tip: Install dependencies with 'pnpm install'"
  '';
}
