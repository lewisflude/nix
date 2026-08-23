{
  pkgs,
  pog,
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
    pkgs.coreutils
    pkgs.git
    pkgs.nix
    pkgs.nvfetcher
    pkgs.gum
    pkgs.jq
  ];

  script =
    helpers: with helpers; ''
      find_flake_dir() {
        if [ -n "''${NIX_CONFIG_ROOT:-}" ]; then
          printf '%s\n' "$NIX_CONFIG_ROOT"
        elif git_root=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null); then
          printf '%s\n' "$git_root"
        else
          printf '%s\n' "$PWD"
        fi
      }

      FLAKE_DIR="$(find_flake_dir)"
      [ -f "$FLAKE_DIR/flake.nix" ] || die "Not in a flake checkout: $FLAKE_DIR"
      [ -w "$FLAKE_DIR" ] || die "Flake checkout is not writable: $FLAKE_DIR"
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
          # Use GITHUB_TOKEN if available for higher rate limits.
          # /run/secrets, not /run/secrets-for-users: only secrets declared with
          # `neededForUsers = true` land in the latter, and in modules/sops.nix
          # that is `hashedPassword` alone.
          if [ -r /run/secrets/GITHUB_TOKEN ]; then
            GITHUB_TOKEN="$(cat /run/secrets/GITHUB_TOKEN)"
            export GITHUB_TOKEN
            NIX_CONFIG="access-tokens = github.com=$GITHUB_TOKEN"
            export NIX_CONFIG
          fi
          nix flake update || die "Failed to update flake inputs"
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
            nvfetcher -c zsh-plugins.toml -o _sources || die "Failed to update ZSH plugins"
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
          nvfetcher -c sources.toml -o _sources || die "Failed to update overlay sources"
          green "✅ Overlay sources updated"
          cyan "   Note: You may need to update additional hashes (like npmDepsHash) manually"
        fi
      else
        debug "No overlays/sources.toml found, skipping"
      fi

      # Report inputs that `nix flake update` cannot move, so pins that have
      # quietly gone stale are visible instead of silently frozen forever.
      cyan "4️⃣  Pinned Inputs"
      cd "$FLAKE_DIR" || die "Failed to change to flake directory"
      PINNED=$(jq -r '
        . as $lock
        | $lock.nodes.root.inputs
        | to_entries[]
        | .key as $name
        | ($lock.nodes[(.value | if type == "array" then .[0] else . end)]) as $node
        # A ref only counts as a pin when it names a commit or a tag; branch
        # refs (master, nixos-unstable, latest) still move on update.
        | ($node.original.rev // (
            $node.original.ref // ""
            | select(test("^[0-9a-f]{7,40}$") or test("^v?[0-9]+\\."))
          )) as $pin
        | select($pin != null and $pin != "")
        | "\($name)\t\($pin[0:12])\t\($node.locked.lastModified // 0)"
      ' flake.lock) || die "Failed to read flake.lock"

      if [ -z "$PINNED" ]; then
        green "✅ No commit- or tag-pinned inputs"
      else
        echo "  Frozen until bumped by hand:"
        NOW=$(date +%s)
        while IFS=$'\t' read -r pin_name pin_rev pin_time; do
          AGE=$(( (NOW - pin_time) / 86400 ))
          LINE=$(printf '  %-22s %-14s %4d days old' "$pin_name" "$pin_rev" "$AGE")
          if [ "$AGE" -gt 365 ]; then
            red "$LINE"
          elif [ "$AGE" -gt 180 ]; then
            yellow "$LINE"
          else
            echo "$LINE"
          fi
        done <<< "$PINNED"
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
