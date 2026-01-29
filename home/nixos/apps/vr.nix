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
  wivrn-client-32bit = pkgs.pkgsi686Linux.wivrn.override {
    clientLibOnly = true;
  };

  # Helper script to switch to WiVRn as default OpenXR runtime
  vr-use-wivrn = pkgs.writeShellApplication {
    name = "vr-use-wivrn";
    text = ''
      RUNTIME_FILE="$HOME/.config/openxr/1/active_runtime.json"
      WIVRN_RUNTIME="${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json"

      if [ ! -f "$WIVRN_RUNTIME" ]; then
        echo "Error: WiVRn runtime not found at $WIVRN_RUNTIME"
        exit 1
      fi

      mkdir -p "$(dirname "$RUNTIME_FILE")"
      ln -sf "$WIVRN_RUNTIME" "$RUNTIME_FILE"
      echo "✓ Switched default OpenXR runtime to WiVRn"
      echo "  Runtime: $RUNTIME_FILE -> $WIVRN_RUNTIME"
    '';
  };

  # Helper script to show current OpenXR runtime
  vr-which-runtime = pkgs.writeShellApplication {
    name = "vr-which-runtime";
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
        if echo "$RUNTIME_PATH" | grep -q "wivrn"; then
          echo "  → WiVRn (Monado-based) [32-bit]"
        elif echo "$RUNTIME_PATH" | grep -q "steamvr"; then
          echo "  → SteamVR [32-bit]"
        else
          echo "  → Unknown runtime [32-bit]"
        fi
      else
        echo "  ⚠️  Not configured (32-bit VR games won't work)"
      fi
    '';
  };

  # Helper to show Steam launch options for each runtime
  vr-launch-options = pkgs.writeShellApplication {
    name = "vr-launch-options";
    text = ''
      echo "=== VR Runtime Launch Options for Steam ==="
      echo ""
      echo "To use WiVRn for a specific game:"
      echo "  XR_RUNTIME_JSON=${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json %command%"
      echo ""
      echo "For 64-bit OpenVR games with xrizer (WiVRn):"
      echo "  xrizer PRESSURE_VESSEL_FILESYSTEMS_RW=\$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%"
      echo ""
      echo "---"
      echo ""
      echo "Current default runtime:"
      vr-which-runtime
    '';
    runtimeInputs = [ vr-which-runtime ];
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
    vr-launch-options
    vr-fix-steamvr
  ]
  ++ lib.optionals wivrnEnabled [
    vr-use-wivrn
    pkgs.wayvr # Desktop overlay for VR
    pkgs.android-tools # ADB for wired VR fallback
    pkgs.xrizer-multilib # OpenVR to OpenXR translation (32-bit + 64-bit)
  ];

  # CRITICAL: OpenXR runtime configuration for sandboxed apps (Steam)
  # Required for Steam pressure-vessel containers to find the OpenXR runtime
  # Set default runtime based on configuration
  xdg.configFile."openxr/1/active_runtime.json" =
    mkIf ((osConfig.host.features.vr.wivrn.defaultRuntime or false) && wivrnEnabled)
      {
        source = "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json";
        force = true; # Overwrite existing file (may be from previous setup)
      };

  # 32-bit OpenXR runtime for 32-bit VR games
  # Automatically used by 32-bit applications (e.g., Half-Life 2: VR mod)
  xdg.configFile."openxr/1/active_runtime.i686.json" = mkIf wivrnEnabled {
    source = "${wivrn-client-32bit}/share/openxr/1/openxr_wivrn.i686.json";
    force = true;
  };

  # OpenVR paths for xrizer (OpenVR to OpenXR translation)
  # Required for SteamVR games to work via xrizer
  xdg.configFile."openvr/openvrpaths.vrpath" = mkIf wivrnEnabled {
    force = true; # Overwrite existing file (may be from previous setup)
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
}
