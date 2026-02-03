# VR home-manager configuration (NixOS only)
# Dendritic pattern: Full implementation as flake.modules.homeManager.vrHome
{ config, ... }:
{
  flake.modules.homeManager.vrHome =
    {
      config,
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    let
      vrEnabled = osConfig.host.features.vr.enable or false;
      wivrnEnabled = (osConfig.host.features.vr.wivrn.enable or false) && vrEnabled;

      wivrn-client-32bit = pkgs.pkgsi686Linux.wivrn.override { clientLibOnly = true; };

      vr-which-runtime = pkgs.writeShellApplication {
        name = "vr-which-runtime";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          RUNTIME_64="$HOME/.config/openxr/1/active_runtime.json"
          RUNTIME_32="$HOME/.config/openxr/1/active_runtime.i686.json"
          echo "=== OpenXR Runtime Configuration ==="
          echo ""
          echo "64-bit runtime (for most VR games):"
          if [ -f "$RUNTIME_64" ]; then
            RUNTIME_PATH=$(readlink -f "$RUNTIME_64")
            echo "  $RUNTIME_PATH"
            if echo "$RUNTIME_PATH" | grep -q "wivrn"; then echo "  → WiVRn (Monado-based)"
            elif echo "$RUNTIME_PATH" | grep -q "steamvr"; then echo "  → SteamVR"
            else echo "  → Unknown runtime"; fi
          else echo "  ⚠️  Not configured"; fi
          echo ""
          echo "32-bit runtime (for Half-Life 2 VR, etc.):"
          if [ -f "$RUNTIME_32" ]; then
            RUNTIME_PATH=$(readlink -f "$RUNTIME_32")
            echo "  $RUNTIME_PATH"
          else echo "  ⚠️  Not configured (32-bit VR games won't work)"; fi
        '';
      };

      vr-fix-steamvr = pkgs.writeShellApplication {
        name = "vr-fix-steamvr";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          echo "=== SteamVR Diagnostic & Fix Tool ==="
          STEAM_ROOT="$HOME/.local/share/Steam"
          STEAMVR_PATH="$STEAM_ROOT/steamapps/common/SteamVR"
          if [ ! -d "$STEAM_ROOT" ]; then echo "❌ Steam not found"; exit 1; fi
          echo "✓ Steam found"
          if [ ! -d "$STEAMVR_PATH" ]; then echo "❌ SteamVR not installed"; exit 1; fi
          echo "✓ SteamVR installed"
          if [ ! -d "$STEAMVR_PATH/bin/linux64" ]; then echo "❌ Linux runtime missing"; exit 1; fi
          echo "✓ Linux runtime found"
          if [ ! -f "$STEAMVR_PATH/bin/linux64/vrserver" ]; then echo "❌ vrserver missing"; exit 1; fi
          echo "✓ vrserver found"
          echo "=== All checks passed! ==="
        '';
      };
    in
    lib.mkIf (vrEnabled && pkgs.stdenv.isLinux) {
      home.packages = [
        vr-which-runtime
        vr-fix-steamvr
      ]
      ++ lib.optionals wivrnEnabled [
        pkgs.wayvr
        pkgs.android-tools
      ];

      xdg.configFile."openxr/1/active_runtime.json" = lib.mkIf wivrnEnabled {
        source = "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json";
        force = true;
      };

      xdg.configFile."openxr/1/active_runtime.i686.json" = lib.mkIf wivrnEnabled {
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

      xdg.configFile."openvr/openvrpaths.vrpath" = lib.mkIf wivrnEnabled {
        force = true;
        text = builtins.toJSON {
          version = 1;
          jsonid = "vrpathreg";
          external_drivers = null;
          config = [ "${config.xdg.dataHome}/Steam/config" ];
          log = [ "${config.xdg.dataHome}/Steam/logs" ];
          runtime = [ "${pkgs.xrizer-multilib}/lib/xrizer" ];
        };
      };

      xdg.desktopEntries = lib.mkIf (osConfig.host.features.gaming.steam or false) {
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
    };
}
