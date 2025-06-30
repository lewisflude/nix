{ pkgs, ... }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs_24
    nodePackages_latest.pnpm
    nodePackages_latest.typescript
    nodePackages_latest.eslint
    nodePackages_latest.prettier
    nodePackages_latest."@next/codemod"
    nodePackages_latest.typescript-language-server
    tailwindcss-language-server
  ];

  shellHook = ''
    echo "⚡ Next.js development environment loaded"
    echo "Node version: $(node --version)"
    echo "Next.js ready for development"

    # Set up aliases for common Next.js commands
    alias dev="pnpm dev"
    alias build="pnpm build"
    alias start="pnpm start"
    alias lint="pnpm lint"
    alias type-check="pnpm type-check"

    # Auto-install dependencies if needed
    if [[ -f "package.json" && ! -d "node_modules" ]]; then
      echo "📦 Installing dependencies..."
      pnpm install
    fi
  '';
}
