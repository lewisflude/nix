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
  immersedUrl = "https://static.immersed.com/dl/Immersed.dmg";
  appName = "Immersed";
  appPath = "/Applications/${appName}.app";
in
{
  config = lib.mkIf (vrEnabled && immersedEnabled) {
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
