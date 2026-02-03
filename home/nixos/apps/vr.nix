{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;
  vrEnabled = osConfig.host.features.vr.enable or false;
  wivrnEnabled = (osConfig.host.features.vr.wivrn.enable or false) && vrEnabled;

  # 32-bit WiVRn client library for 32-bit VR games (e.g., Half-Life 2: VR)
  # clientLibOnly = true skips GUI deps (qtwebengine doesn't support i686)
  wivrn-client-32bit = pkgs.pkgsi686Linux.wivrn.override {
    clientLibOnly = true;
  };

  # Helper script to show current OpenXR runtime
  vr-which-runtime = pkgs.writeShellApplication {
    name = "vr-which-runtime";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      RUNTIME_64="$HOME/.config/openxr/1/active_runtime.json"
      RUNTIME_32="$HOME/.config/openxr/1/active_runtime.i686.json"

      echo "=== OpenXR Runtime Configuration ==="
      echo ""

      # Check 64-bit runtime
      echo "64-bit runtime (for most VR games):"
      if [ -f "$RUNTIME_64" ]; then
        RUNTIME_PATH=$(readlink -f "$RUNTIME_64")
        echo "  $RUNTIME_PATH"
        if echo "$RUNTIME_PATH" | grep -q "wivrn"; then
          echo "  → WiVRn (Monado-based)"
        elif echo "$RUNTIME_PATH" | grep -q "steamvr"; then
          echo "  → SteamVR"
        else
          echo "  → Unknown runtime"
        fi
      else
        echo "  ⚠️  Not configured"
      fi

      echo ""

      # Check 32-bit runtime
      echo "32-bit runtime (for Half-Life 2 VR, etc.):"
      if [ -f "$RUNTIME_32" ]; then
        RUNTIME_PATH=$(readlink -f "$RUNTIME_32")
        echo "  $RUNTIME_PATH"

        # Check JSON content to identify runtime
        RUNTIME_NAME=""
        if [ -f "$RUNTIME_PATH" ]; then
          CONTENT=$(cat "$RUNTIME_PATH")
          if echo "$CONTENT" | jq -e '.runtime.library_path' > /dev/null 2>&1; then
            LIBRARY_PATH=$(echo "$CONTENT" | jq -r '.runtime.library_path')
            if echo "$LIBRARY_PATH" | grep -q "wivrn"; then
              RUNTIME_NAME="WiVRn (Monado-based) [32-bit]"
            elif echo "$LIBRARY_PATH" | grep -q "steamvr"; then
              RUNTIME_NAME="SteamVR [32-bit]"
            fi
          fi
        fi

        # Fallback to path check if JSON parsing fails
        if [ -z "$RUNTIME_NAME" ]; then
          if echo "$RUNTIME_PATH" | grep -q "wivrn"; then
            RUNTIME_NAME="WiVRn (Monado-based) [32-bit]"
          elif echo "$RUNTIME_PATH" | grep -q "steamvr"; then
            RUNTIME_NAME="SteamVR [32-bit]"
          else
            RUNTIME_NAME="Unknown runtime [32-bit]"
          fi
        fi

        echo "  → $RUNTIME_NAME"
      else
        echo "  ⚠️  Not configured (32-bit VR games won't work)"
      fi
    '';
  };

  # Helper to diagnose and fix SteamVR installation
  vr-fix-steamvr = pkgs.writeShellApplication {
    name = "vr-fix-steamvr";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      echo "=== SteamVR Diagnostic & Fix Tool ==="
      echo ""

      STEAM_ROOT="$HOME/.local/share/Steam"
      STEAMVR_PATH="$STEAM_ROOT/steamapps/common/SteamVR"

      # Check if Steam is installed
      if [ ! -d "$STEAM_ROOT" ]; then
        echo "❌ Steam not found at $STEAM_ROOT"
        echo "   Please launch Steam at least once first"
        exit 1
      fi

      echo "✓ Steam found at $STEAM_ROOT"
      echo ""

      # Check if SteamVR is installed
      if [ ! -d "$STEAMVR_PATH" ]; then
        echo "❌ SteamVR not installed"
        echo ""
        echo "To install SteamVR:"
        echo "  1. Open Steam"
        echo "  2. Search for 'SteamVR' in the store"
        echo "  3. Click 'Play Game' or 'Install'"
        echo "  4. Let it download and install"
        echo "  5. Run this script again"
        exit 1
      fi

      echo "✓ SteamVR installed at $STEAMVR_PATH"
      echo ""

      # Check for Linux runtime
      LINUX_RUNTIME="$STEAMVR_PATH/bin/linux64"
      if [ ! -d "$LINUX_RUNTIME" ]; then
        echo "❌ SteamVR Linux runtime missing"
        echo ""
        echo "To fix:"
        echo "  1. Right-click SteamVR in Steam Library"
        echo "  2. Properties → Installed Files → Verify integrity of game files"
        echo "  3. Let Steam download missing files"
        echo "  4. Run this script again"
        exit 1
      fi

      echo "✓ SteamVR Linux runtime found"
      echo ""

      # Check vrserver binary
      VRSERVER="$LINUX_RUNTIME/vrserver"
      if [ ! -f "$VRSERVER" ]; then
        echo "❌ vrserver binary missing at $VRSERVER"
        echo "   Run 'Verify integrity of game files' in Steam"
        exit 1
      fi

      echo "✓ vrserver binary found"
      echo ""

      # Check Steam Linux Runtime (for compatibility tools)
      RUNTIME_PATHS=(
        "$STEAM_ROOT/steamapps/common/SteamLinuxRuntime_sniper"
        "$STEAM_ROOT/steamapps/common/SteamLinuxRuntime_soldier"
      )

      RUNTIME_FOUND=false
      for runtime in "''${RUNTIME_PATHS[@]}"; do
        if [ -d "$runtime" ]; then
          echo "✓ Steam Linux Runtime found: $(basename "$runtime")"
          RUNTIME_FOUND=true
        fi
      done

      if [ "$RUNTIME_FOUND" = false ]; then
        echo "⚠️  Steam Linux Runtime not found"
        echo "   Steam will auto-download this when needed"
        echo ""
      fi

      echo ""
      echo "=== All checks passed! ==="
      echo ""
      echo "Next steps:"
      echo "  1. Start WiVRn: systemctl --user start wivrn"
      echo "  2. Connect your Quest headset to WiVRn"
      echo "  3. Launch VR games with launch options from 'vr-launch-options'"
    '';
  };
in
mkIf vrEnabled {
  # User VR packages
  home.packages = [
    vr-which-runtime
    vr-fix-steamvr
  ]
  ++ lib.optionals wivrnEnabled [
    pkgs.wayvr # Desktop overlay for VR
    pkgs.android-tools # ADB for wired VR fallback
  ];

  # OpenXR 64-bit runtime - managed by services.wivrn.defaultRuntime
  # This creates a symlink to WiVRn's OpenXR runtime for Steam and other apps
  xdg.configFile."openxr/1/active_runtime.json" = mkIf wivrnEnabled {
    source = "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json";
    force = true;
  };

  # 32-bit OpenXR runtime for 32-bit VR games
  # Automatically used by 32-bit applications (e.g., Half-Life 2: VR mod)
  # Manual JSON since clientLibOnly doesn't generate it
  xdg.configFile."openxr/1/active_runtime.i686.json" = mkIf wivrnEnabled {
    force = true;
    text = builtins.toJSON {
      file_format_version = "1.0.0";
      runtime = {
        name = "Monado";
        library_path = "${wivrn-client-32bit}/lib/wivrn/libopenxr_wivrn.so";
        MND_libmonado_path = "${wivrn-client-32bit}/lib/wivrn/libmonado_wivrn.so";
      };
    };
  };

  # OpenVR paths for xrizer (OpenVR to OpenXR translation layer)
  # Enables OpenVR games to work with WiVRn's OpenXR runtime
  xdg.configFile."openvr/openvrpaths.vrpath" = mkIf wivrnEnabled {
    force = true;
    text =
      let
        steam = "${config.xdg.dataHome}/Steam";
      in
      builtins.toJSON {
        version = 1;
        jsonid = "vrpathreg";
        external_drivers = null;
        config = [ "${steam}/config" ];
        log = [ "${steam}/logs" ];
        runtime = [ "${pkgs.xrizer-multilib}/lib/xrizer" ];
      };
  };

  # Desktop entries for SteamVR URI handlers
  # Required for setting OpenXR runtime through SteamVR's GUI
  # Fixes "No apps available" error when clicking vrmonitor://openxr/makedefault
  # See: https://old.reddit.com/r/linuxmint/comments/1egvi8y/cant_set_openxr_no_apps_available/
  xdg.desktopEntries = mkIf (vrEnabled && osConfig.host.features.gaming.steam or false) {
    valve-URI-steamvr = {
      name = "URI-steamvr";
      comment = "URI handler for steamvr://";
      exec = "${config.xdg.dataHome}/Steam/steamapps/common/SteamVR/bin/linux64/vrurlhandler %U";
      terminal = false;
      type = "Application";
      categories = [ "Game" ];
      mimeType = [ "x-scheme-handler/steamvr" ];
    };

    valve-URI-vrmonitor = {
      name = "URI-vrmonitor";
      comment = "URI handler for vrmonitor://";
      exec = "${config.xdg.dataHome}/Steam/steamapps/common/SteamVR/bin/linux64/../vrmonitor.sh %U";
      terminal = false;
      type = "Application";
      categories = [ "Game" ];
      mimeType = [ "x-scheme-handler/vrmonitor" ];
    };
  };
}
