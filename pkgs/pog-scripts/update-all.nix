{
  pkgs,
  pog,
  config-root,
}:
pog.pog {
  name = "update-all";
  version = "3.0.0";
  description = "Update all dependencies in the Nix configuration";

  flags = [
    {
      name = "dry_run";
      short = "d";
      bool = true;
      description = "Show what would be updated without making changes";
    }
    {
      name = "skip_flake";
      short = "f";
      bool = true;
      description = "Skip flake.lock update";
    }
    {
      name = "skip_plugins";
      short = "p";
      bool = true;
      description = "Skip ZSH plugins update";
    }
  ];

  runtimeInputs = [
    pkgs.git
    pkgs.nix
    pkgs.nvfetcher
    pkgs.gum
  ];

  script =
    helpers: with helpers; ''
      FLAKE_DIR="${config-root}"
      cd "$FLAKE_DIR" || die "Failed to change to flake directory"

      blue "🚀 Starting Update Process"

      # Check for uncommitted changes
      if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        yellow "⚠️  You have uncommitted changes"
        if ! ${flag "dry_run"}; then
          ${confirm { prompt = "Continue anyway?"; }}
        fi
      fi

      # Update flake inputs
      if ! ${flag "skip_flake"}; then
        cyan "1️⃣  Updating Flake Inputs"
        if ${flag "dry_run"}; then
          debug "DRY RUN: Would run 'nix flake update'"
        else
          # Use GITHUB_TOKEN if available for higher rate limits
          if [ -r /run/secrets-for-users/GITHUB_TOKEN ]; then
            export GITHUB_TOKEN="$(cat /run/secrets-for-users/GITHUB_TOKEN)"
            export NIX_CONFIG="access-tokens = github.com=$GITHUB_TOKEN"
          fi
          nix flake update
          green "✅ Flake inputs updated"
        fi
      else
        yellow "Skipping flake update"
      fi

      # Update ZSH plugins
      if ! ${flag "skip_plugins"}; then
        cyan "2️⃣  Updating ZSH Plugins"
        if [ -f "$FLAKE_DIR/home/common/zsh-plugins.toml" ]; then
          if ${flag "dry_run"}; then
            debug "DRY RUN: Would update ZSH plugins with nvfetcher"
          else
            cd "$FLAKE_DIR/home/common" || die "Failed to change to home/common directory"
            nvfetcher -c zsh-plugins.toml -o _sources 2>&1 | grep -v "trace:" || true
            green "✅ ZSH plugins updated"
          fi
        else
          debug "No zsh-plugins.toml found, skipping"
        fi
      else
        yellow "Skipping plugin updates"
      fi

      # Summary
      if ! ${flag "dry_run"}; then
        cyan "📊 Update Summary"

        if ! ${flag "skip_flake"}; then
          git diff --quiet flake.lock 2>/dev/null && echo "flake.lock: No changes" || echo "flake.lock: Updated"
        fi

        if ! ${flag "skip_plugins"} && [ -d "$FLAKE_DIR/home/common/_sources" ]; then
          git diff --quiet home/common/_sources/ 2>/dev/null && echo "_sources/: No changes" || echo "_sources/: Updated"
        fi

        echo ""
        green "✅ Update completed!"
        cyan "Next steps:"
        echo "  1. Review: git diff"
        if [[ "$(uname)" == "Darwin" ]]; then
          echo "  2. Test: darwin-rebuild build --flake ~/.config/nix"
        else
          echo "  2. Test: nh os build"
        fi
        echo "  3. Commit: git add -A && git commit -m 'chore: update dependencies'"
      else
        green "✨ DRY RUN completed - no changes made"
      fi
    '';
}
