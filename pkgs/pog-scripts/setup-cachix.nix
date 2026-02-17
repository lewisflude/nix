{
  pkgs,
  pog,
  ...
}:
pog.pog {
  name = "setup-cachix";
  version = "2.0.0";
  description = "Setup Cachix binary cache for faster builds";

  arguments = [
    {
      name = "command";
      description = "Command to run (user, ci, push, push-shells, push-all, watch, stats)";
      default = "user";
    }
  ];

  argumentCompletion = ''printf "%s\n" user ci push push-shells push-all watch stats'';

  flags = [
    {
      name = "cache";
      short = "c";
      description = "Cachix cache name";
      default = "lewisflude";
      envVar = "CACHIX_CACHE_NAME";
    }
    {
      name = "system";
      short = "s";
      description = "System to push (for push command)";
      argument = "SYSTEM";
    }
  ];

  runtimeInputs = [
    pkgs.cachix
    pkgs.jq
    pkgs.nix
  ];

  script =
    helpers: with helpers; ''
      CACHE_NAME="$cache"
      COMMAND="$1"


      if ! command -v cachix &> /dev/null; then
        die "cachix not found in PATH"
      fi

      debug "Cachix version: $(cachix --version)"
      debug "Cache name: $CACHE_NAME"
      debug "Command: $COMMAND"


      setup_user() {
        blue "📥 Setting up Cachix for read access..."

        yellow "→ Adding nix-community cache..."
        cachix use nix-community || true

        if [ -n "$CACHE_NAME" ]; then
          yellow "→ Adding custom cache: $CACHE_NAME..."
          if cachix use "$CACHE_NAME"; then
            green "✓ Cache added successfully"
          else
            yellow "⚠️  Cache '$CACHE_NAME' not found. Create it at https://cachix.org"
          fi
        fi

        green "✓ Cachix configured for read access"
        green "✓ Binary caches will now be used for faster builds"
      }


      setup_ci() {
        blue "📤 Setting up Cachix for write access..."

        if [ -z "''${CACHIX_AUTH_TOKEN:-}" ]; then
          red "✗ CACHIX_AUTH_TOKEN not set"
          yellow "→ Get your token from: https://app.cachix.org/personal-auth-tokens"
          yellow "→ Then run: export CACHIX_AUTH_TOKEN='your-token'"
          die "Authentication token required for CI setup"
        fi

        yellow "→ Authenticating with Cachix..."
        echo "$CACHIX_AUTH_TOKEN" | cachix authtoken

        yellow "→ Setting up cache: $CACHE_NAME..."
        cachix use "$CACHE_NAME"

        green "✓ Cachix configured for write access"
        green "✓ You can now push to cache: $CACHE_NAME"
      }


      push_system() {
        local sys="''${system:-}"

        if [ -z "$sys" ]; then
          die "No system specified. Use --system flag or provide as argument"
        fi

        blue "📤 Pushing system to Cachix: $sys"

        yellow "→ Building system..."
        nix build ".#$sys" \
          --json \
          | jq -r '.[].outputs | to_entries[].value' \
          | cachix push "$CACHE_NAME"

        green "✓ System pushed to cache: $CACHE_NAME"
      }


      push_shells() {
        blue "📤 Pushing development shells to Cachix"


        local shells
        shells=$(nix flake show --json 2>/dev/null | jq -r '.devShells."x86_64-linux" | keys[]' || echo "default")

        for shell in $shells; do
          yellow "→ Pushing shell: $shell..."
          nix build ".#devShells.x86_64-linux.$shell" \
            --json \
            | jq -r '.[].outputs | to_entries[].value' \
            | cachix push "$CACHE_NAME" || true
        done

        green "✓ Development shells pushed to cache"
      }


      push_all() {
        blue "📤 Building and pushing ALL flake outputs to Cachix"
        yellow "→ This uses devour-flake for efficient single-evaluation builds"
        yellow "→ Building all outputs (this may take a while)..."

        # Use devour-flake to build all outputs in one evaluation
        # This is much faster than building outputs individually
        nix build github:srid/devour-flake \
          -L --no-link --print-out-paths \
          --override-input flake . \
          | cachix push "$CACHE_NAME"

        green "✓ All outputs built and pushed to cache: $CACHE_NAME"
        yellow "→ This includes: packages, apps, devShells, checks, nixosConfigurations, darwinConfigurations"
      }


      watch_build() {
        blue "👀 Watching for builds and auto-pushing to Cachix"
        yellow "→ This will push all new builds to: $CACHE_NAME"
        yellow "→ Press Ctrl+C to stop"

        shift
        cachix watch-exec "$CACHE_NAME" -- nix build "$@"
      }


      show_stats() {
        blue "📊 Cache Statistics"

        cyan "Configured caches:"
        cachix list || echo "No caches configured"

        echo ""
        cyan "Cache details:"
        echo "  Cache: $CACHE_NAME"
        echo "  URL: https://$CACHE_NAME.cachix.org"

        echo ""
        cyan "Local Nix store size:"
        du -sh /nix/store 2>/dev/null || echo "  Unable to determine"
      }


      case "$COMMAND" in
        user)
          setup_user
          ;;
        ci|maintainer)
          setup_ci
          ;;
        push)
          push_system
          ;;
        push-shells)
          push_shells
          ;;
        push-all)
          push_all
          ;;
        watch)
          watch_build "$@"
          ;;
        stats)
          show_stats
          ;;
        help|--help|-h)
          cyan "Cachix Setup Tool"
          echo ""
          echo "Commands:"
          echo "  user         Setup for read-only access (default)"
          echo "  ci           Setup for write access (requires CACHIX_AUTH_TOKEN)"
          echo "  push         Push a system configuration to cache"
          echo "  push-shells  Push all development shells to cache"
          echo "  push-all     Build and push ALL flake outputs (uses devour-flake)"
          echo "  watch        Watch and auto-push build results"
          echo "  stats        Show cache statistics"
          echo ""
          echo "Flags:"
          echo "  -c, --cache <name>   Cachix cache name (default: nix-config)"
          echo "  -s, --system <sys>   System to push (for push command)"
          echo ""
          echo "Environment:"
          echo "  CACHIX_CACHE_NAME    Cache name override"
          echo "  CACHIX_AUTH_TOKEN    Auth token for CI/write access"
          echo ""
          echo "Examples:"
          echo "  setup-cachix user"
          echo "  setup-cachix ci"
          echo "  setup-cachix push --system nixosConfigurations.jupiter"
          echo "  setup-cachix push-all  # Build and cache everything efficiently"
          echo "  setup-cachix watch nix build .#some-package"
          ;;
        *)
          die "Unknown command: $COMMAND. Run 'setup-cachix help' for usage"
          ;;
      esac
    '';
}
