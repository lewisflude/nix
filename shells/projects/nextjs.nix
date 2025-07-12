{ pkgs, ... }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    myPackages.nodejs.full
    tailwindcss-language-server
  ];

  shellHook = ''
    echo "⚡ Next.js development environment loaded"
    echo "Node version: $(node --version)"
    echo "Next.js ready for development"

    alias dev="pnpm dev"
    alias build="pnpm build"
    alias start="pnpm start"
    alias lint="biome lint ."
    alias format="biome format . --write"
    alias check="biome check ."
    alias type-check="pnpm type-check"

    if [[ -f "package.json" && ! -d "node_modules" ]]; then
      echo "📦 Installing dependencies..."
      pnpm install
    fi
  '';
}
