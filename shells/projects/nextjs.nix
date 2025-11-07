{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # System provides: node, pnpm, typescript, typescript-language-server
    # Add Next.js-specific tools only
    tailwindcss-language-server
  ];
  shellHook = ''
    echo "⚡ Next.js development environment loaded (using system Node.js)"
    echo "Node version: $(node --version)"
    echo "Next.js ready for development"

    # Project-specific aliases
    alias dev="pnpm dev"
    alias build="pnpm build"
    alias start="pnpm start"
    alias lint="biome lint ."
    alias format="biome format . --write"
    alias check="biome check ."
    alias type-check="pnpm type-check"

    # Auto-install dependencies if needed
    if [[ -f "package.json" && ! -d "node_modules" ]]; then
      echo "📦 Installing dependencies..."
      pnpm install
    fi
  '';
}
