{
  pkgs,
  pog,
  config-root,
}:
pog.pog {
  name = "update-all";
  version = "2.0.0";
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
      name = "skip_packages";
      short = "k";
      bool = true;
      description = "Skip custom package updates";
    }
  ];

  runtimeInputs = with pkgs; [
    git
    nix
    nvfetcher
    gum
    nix-update
  ];

  script = helpers:
    with helpers; ''
      FLAKE_DIR="${config-root}"
      cd "$FLAKE_DIR" || die "Failed to change to flake directory"

      debug "Flake directory: $FLAKE_DIR"
      debug "Dry run: $dry_run"

      blue "🚀 Starting Full Update Process"

      # Check git status
      if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        yellow "⚠️  You have uncommitted changes"
        if ! ${flag "dry_run"}; then
          ${confirm {prompt = "Continue anyway?";}}
        fi
      fi

      # 1. Update flake inputs
      if ! ${flag "skip_flake"}; then
        cyan "1️⃣  Updating Flake Inputs"

        if ${flag "dry_run"}; then
          debug "DRY RUN: Would run 'nix flake update'"
        else
          nix flake update
          green "✅ Flake inputs updated"
        fi
      else
        yellow "Skipping flake update"
      fi

      # 2. Update custom packages with nix-update
      if ! ${flag "skip_packages"}; then
        cyan "2️⃣  Updating Custom Packages"

        # List of packages to update (file path)
        PACKAGES=(
          "modules/nixos/services/home-assistant/custom-components/home-llm.nix"
        )

        for pkg_file in "''${PACKAGES[@]}"; do
          if [ -f "$FLAKE_DIR/$pkg_file" ]; then
            pkg_name=$(basename "$pkg_file" .nix)
            if ${flag "dry_run"}; then
              debug "DRY RUN: Would update $pkg_name with nix-update"
            else
              debug "Updating $pkg_name..."
              # Update to latest version, skip if no new version
              if nix-update --override-filename "$pkg_file" 2>&1 | tee /tmp/nix-update.log | grep -q "Not updating"; then
                echo "  $pkg_name: Already up to date"
              else
                green "  ✅ $pkg_name: Updated"
              fi
            fi
          else
            debug "Package file not found: $pkg_file"
          fi
        done

        green "✅ Custom packages checked"
      else
        yellow "Skipping custom package updates"
      fi

      # 3. Update ZSH plugins
      if ! ${flag "skip_plugins"}; then
        cyan "3️⃣  Updating ZSH Plugins"

        if [ -f "$FLAKE_DIR/home/common/zsh-plugins.toml" ]; then
          if ${flag "dry_run"}; then
            debug "DRY RUN: Would update ZSH plugins with nvfetcher"
          else
            debug "Running nvfetcher for ZSH plugins..."
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

      # 4. Show summary
      cyan "📊 Update Summary"

      if ! ${flag "dry_run"}; then
        # Show flake.lock changes
        if ! ${flag "skip_flake"} && git diff --quiet flake.lock 2>/dev/null; then
          echo "flake.lock: No changes"
        elif ! ${flag "skip_flake"}; then
          echo "flake.lock: Updated"
          git diff flake.lock --stat 2>/dev/null || true
        fi

        # Show custom package changes
        if ! ${flag "skip_packages"}; then
          PACKAGES=(
            "modules/nixos/services/home-assistant/custom-components/home-llm.nix"
          )
          for pkg_file in "''${PACKAGES[@]}"; do
            if [ -f "$pkg_file" ]; then
              if git diff --quiet "$pkg_file" 2>/dev/null; then
                echo "$pkg_file: No changes"
              else
                echo "$pkg_file: Updated"
              fi
            fi
          done
        fi

        # Show plugin changes
        if ! ${flag "skip_plugins"} && [ -d "$FLAKE_DIR/home/common/_sources" ]; then
          if git diff --quiet home/common/_sources/ 2>/dev/null; then
            echo "_sources/: No changes"
          else
            echo "_sources/: Updated"
            git diff home/common/_sources/ --stat 2>/dev/null || true
          fi
        fi

        echo ""
        green "✅ Update completed successfully!"
        echo ""
        cyan "Next steps:"
        echo "  1. Review changes: git diff"
        if [[ "$(uname)" == "Darwin" ]]; then
          echo "  2. Test: darwin-rebuild build --flake ~/.config/nix"
        else
          echo "  2. Test: nh os build"
        fi
        echo "  3. Commit: git add -A && git commit -m 'chore: update dependencies'"
      else
        debug "DRY RUN completed - no changes made"
      fi

      green "✨ Done!"
    '';
}
