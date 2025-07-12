{ pkgs, ... }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs_24
    nodePackages_latest.pnpm
    nodePackages_latest.typescript
    nodePackages_latest.prisma
    nodePackages_latest.eslint
    nodePackages_latest.prettier
    nodePackages_latest.typescript-language-server
    postgresql
    redis
    curl
    jq
    httpie
    nodePackages_latest.pm2
  ];

  shellHook = ''
    echo "🔧 API Backend development environment loaded"
    echo "Node version: $(node --version)"

    alias dev="pnpm dev"
    alias db:migrate="pnpm db:migrate"
    alias db:seed="pnpm db:seed"
    alias db:studio="pnpm db:studio"
    alias test="pnpm test"
    alias test:watch="pnpm test:watch"

    export NODE_ENV=development
    export DATABASE_URL="postgresql://localhost:5432/dev"
    export REDIS_URL="redis://localhost:6379"

    if command -v postgres >/dev/null 2>&1; then
      if ! pg_isready -q; then
        echo "🗄️  Starting PostgreSQL..."
        pg_ctl -D ~/.postgres -l ~/.postgres/server.log start
      fi
    fi
  '';
}
