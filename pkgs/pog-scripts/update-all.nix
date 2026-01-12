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
    {
      name = "skip_immersed";
      short = "i";
      bool = true;
      description = "Skip Immersed VR update";
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

      # Update overlay sources (optional - using nvfetcher)
      if [ -f "$FLAKE_DIR/overlays/sources.toml" ]; then
        cyan "3️⃣  Updating Overlay Sources"
        if ${flag "dry_run"}; then
          debug "DRY RUN: Would update overlay sources with nvfetcher"
        else
          cd "$FLAKE_DIR/overlays" || die "Failed to change to overlays directory"
          nvfetcher -c sources.toml -o _sources 2>&1 | grep -v "trace:" || true
          green "✅ Overlay sources updated"
          cyan "   Note: You may need to update additional hashes (like npmDepsHash) manually"
        fi
      else
        debug "No overlays/sources.toml found, skipping"
      fi

      # Update Immersed VR (x86_64-linux only)
      if ! ${flag "skip_immersed"}; then
        if [[ "$(uname -m)" == "x86_64" ]] && [[ "$(uname)" == "Linux" ]]; then
          cyan "4️⃣  Updating Immersed VR"
          if ${flag "dry_run"}; then
            debug "DRY RUN: Would update Immersed VR to latest version"
          else
            cd "$FLAKE_DIR" || die "Failed to change to flake directory"
            # Call the update-immersed script
            if command -v update-immersed >/dev/null 2>&1; then
              update-immersed || yellow "⚠️  Failed to update Immersed (continuing anyway)"
            else
              debug "update-immersed command not found in PATH, skipping"
            fi
          fi
        else
          debug "Immersed update only supported on x86_64-linux, skipping"
        fi
      else
        yellow "Skipping Immersed update"
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

        if [ -d "$FLAKE_DIR/overlays/_sources" ]; then
          git diff --quiet overlays/_sources/ 2>/dev/null && echo "overlays/_sources/: No changes" || echo "overlays/_sources/: Updated"
        fi

        if ! ${flag "skip_immersed"}; then
          git diff --quiet overlays/default.nix 2>/dev/null && echo "Immersed VR: No changes" || echo "Immersed VR: Updated"
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
