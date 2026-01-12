{
  pkgs,
  pog,
  config-root,
}:
pog.pog {
  name = "update-immersed";
  version = "1.0.0";
  description = "Automatically update Immersed VR to the latest version";

  flags = [
    {
      name = "dry_run";
      short = "d";
      bool = true;
      description = "Show what would be updated without making changes";
    }
    {
      name = "platform";
      short = "p";
      default = "x86_64-linux";
      description = "Platform to update (x86_64-linux, aarch64-linux, darwin)";
    }
  ];

  runtimeInputs = [
    pkgs.curl
    pkgs.nix
    pkgs.gnused
    pkgs.gum
  ];

  script =
    helpers: with helpers; ''
      FLAKE_DIR="${config-root}"
      OVERLAY_FILE="$FLAKE_DIR/overlays/default.nix"
      PLATFORM="$platform"

      cd "$FLAKE_DIR" || die "Failed to change to flake directory"

      blue "🚀 Updating Immersed VR"

      # Determine download URL based on platform
      case "$PLATFORM" in
        x86_64-linux)
          URL="https://static.immersed.com/dl/Immersed-x86_64.AppImage"
          ;;
        aarch64-linux)
          URL="https://static.immersed.com/dl/Immersed-aarch64.AppImage"
          ;;
        *darwin*)
          URL="https://static.immersed.com/dl/Immersed.dmg"
          ;;
        *)
          die "Unsupported platform: $PLATFORM"
          ;;
      esac

      cyan "Platform: $PLATFORM"
      cyan "URL: $URL"

      # Download the latest version
      cyan "📥 Downloading latest Immersed..."
      TEMP_FILE=$(mktemp)
      if ! curl -fsSL "$URL" -o "$TEMP_FILE"; then
        rm -f "$TEMP_FILE"
        die "Failed to download Immersed from $URL"
      fi

      # Calculate hash
      cyan "🔐 Calculating hash..."
      NEW_HASH=$(nix hash file "$TEMP_FILE")
      rm -f "$TEMP_FILE"

      if [ -z "$NEW_HASH" ]; then
        die "Failed to calculate hash"
      fi

      green "✅ New hash: $NEW_HASH"

      # Check if hash has changed
      cyan "🔍 Checking current hash in overlay..."
      if grep -q "$NEW_HASH" "$OVERLAY_FILE"; then
        green "✅ Immersed is already up to date!"
        exit 0
      fi

      yellow "📝 Hash has changed - update needed"

      if ${flag "dry_run"}; then
        cyan "DRY RUN: Would update $OVERLAY_FILE with new hash"
        debug "New hash: $NEW_HASH"
      else
        # Create backup
        cp "$OVERLAY_FILE" "$OVERLAY_FILE.bak"

        # Update the hash in the overlay file
        # This is tricky - we need to find the right section and update the hash
        case "$PLATFORM" in
          x86_64-linux)
            # Find and replace the x86_64-linux hash
            sed -i "/if prev.stdenv.isLinux && prev.stdenv.isx86_64 then/,/else if prev.stdenv.isLinux && prev.stdenv.isAarch64 then/ s|hash = \"sha256-[^\"]*\"|hash = \"$NEW_HASH\"|" "$OVERLAY_FILE"
            ;;
          aarch64-linux)
            # Find and replace the aarch64-linux hash
            sed -i "/else if prev.stdenv.isLinux && prev.stdenv.isAarch64 then/,/else if prev.stdenv.isDarwin then/ s|hash = \"sha256-[^\"]*\"|hash = \"$NEW_HASH\"|" "$OVERLAY_FILE"
            ;;
          *darwin*)
            # Find and replace the darwin hash
            sed -i "/else if prev.stdenv.isDarwin then/,/else/ s|hash = \"sha256-[^\"]*\"|hash = \"$NEW_HASH\"|" "$OVERLAY_FILE"
            ;;
        esac

        # Format the file
        cyan "🎨 Formatting overlay file..."
        nix fmt "$OVERLAY_FILE" 2>/dev/null || true

        green "✅ Immersed overlay updated!"
        cyan "📋 Changes:"
        echo "  Platform: $PLATFORM"
        echo "  New hash: $NEW_HASH"
        echo ""
        cyan "Next steps:"
        echo "  1. Review: git diff overlays/default.nix"
        echo "  2. Test build: nh os build"
        echo "  3. Apply: nh os switch"
        echo "  4. Commit: git commit -am 'chore(vr): update Immersed to latest version'"

        rm -f "$OVERLAY_FILE.bak"
      fi
    '';
}
