# Immersed VR for macOS (darwin)
# Downloads and manages Immersed VR desktop productivity app
{
  lib,
  config,
  pkgs,
  ...
}:
let
  features = config.host.features or { };
  vrEnabled = (features.vr or { }).enable or false;
  immersedEnabled = ((features.vr or { }).immersed or { }).enable or false;

  # Immersed DMG download URL
  immersedUrl = "https://static.immersed.com/dl/Immersed.dmg";
  appName = "Immersed";
  appPath = "/Applications/${appName}.app";
in
{
  config = lib.mkIf (vrEnabled && immersedEnabled) {
    # Check Immersed installation during activation
    # Auto-install is unreliable during nix-darwin rebuild, so we just notify
    system.activationScripts.checkImmersed.text = ''
      echo "🥽 Checking Immersed VR installation..."

      if [ -d "${appPath}" ]; then
        echo "✅ Immersed is already installed at ${appPath}"
      else
        echo ""
        echo "⚠️  Immersed VR is not installed."
        echo "   Run 'update-immersed-darwin' to install it."
        echo ""
      fi
    '';

    # Add helper script to update Immersed
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "update-immersed-darwin" ''
        #!/bin/bash
        set -euo pipefail

        echo "🔄 Updating Immersed VR..."

        # Remove existing installation
        if [ -d "${appPath}" ]; then
          echo "🗑️  Removing existing installation..."
          rm -rf "${appPath}"
        fi

        # Download fresh copy
        TMPDIR=$(mktemp -d)
        DMG_PATH="$TMPDIR/Immersed.dmg"

        echo "📥 Downloading latest Immersed VR..."
        curl -fsSL "${immersedUrl}" -o "$DMG_PATH"

        echo "📦 Mounting DMG..."
        MOUNT_POINT=$(mktemp -d)
        hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_POINT" -nobrowse -quiet

        echo "📋 Installing ${appName}.app..."
        cp -R "$MOUNT_POINT/${appName}.app" /Applications/

        hdiutil detach "$MOUNT_POINT" -quiet
        rm -rf "$TMPDIR"

        echo "✅ Immersed VR updated successfully!"
      '')
    ];
  };
}
