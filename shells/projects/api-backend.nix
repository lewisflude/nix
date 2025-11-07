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
    # System provides: node, pnpm, typescript
    # Add API backend-specific tools
    postgresql
    redis
    curl
    jq
    httpie
  ];
  shellHook = ''
    echo "🔧 API Backend development environment loaded (using system Node.js)"
    echo "Node version: $(node --version)"
    echo "Database tools: PostgreSQL, Redis"

    # Project-specific aliases
    alias dev="pnpm dev"
    alias db:migrate="pnpm db:migrate"
    alias db:seed="pnpm db:seed"
    alias db:studio="pnpm db:studio"
    alias test="pnpm test"
    alias test:watch="pnpm test:watch"

    # Environment configuration
    export NODE_ENV=development
    export DATABASE_URL="postgresql://localhost:5432/dev"
    export REDIS_URL="redis://localhost:6379"

    # Auto-start PostgreSQL if available
    if command -v postgres >/dev/null 2>&1; then
      if ! pg_isready -q; then
        echo "🗄️  Starting PostgreSQL..."
        pg_ctl -D ~/.postgres -l ~/.postgres/server.log start
      fi
    fi
  '';
}
