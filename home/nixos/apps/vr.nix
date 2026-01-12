{
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;
  vrEnabled = osConfig.host.features.vr.enable or false;

  # Helper script to install Media Foundation codecs for Heresphere
  # Media Foundation is required for proper video codec support in Windows VR apps
  install-mf-codecs = pkgs.writeShellApplication {
    name = "install-mf-codecs";
    text = ''
      set -euo pipefail

      # Default Wine prefix for Heresphere (common locations)
      WINEPREFIX="''${1:-$HOME/.wine}"

      if [ ! -d "$WINEPREFIX" ]; then
        echo "Error: Wine prefix not found at $WINEPREFIX"
        echo ""
        echo "Usage: install-mf-codecs [WINEPREFIX]"
        echo ""
        echo "Examples:"
        echo "  install-mf-codecs                          # Use default ~/.wine"
        echo "  install-mf-codecs ~/.local/share/wineprefixes/heresphere"
        echo ""
        exit 1
      fi

      echo "Installing Media Foundation codecs for Wine prefix: $WINEPREFIX"
      echo "This may take several minutes..."

      WINEPREFIX="$WINEPREFIX" ${pkgs.winetricks}/bin/winetricks -q mf

      echo ""
      echo "Media Foundation codecs installed successfully!"
      echo "You may need to restart Heresphere for the changes to take effect."
    '';
    runtimeInputs = [
      pkgs.winetricks
      pkgs.wine
    ];
  };
in
mkIf vrEnabled {
  # User VR packages
  # Note: Immersed VR is installed via programs.immersed module at system level
  home.packages = [
    # WayVR - Desktop overlay for VR
    # wlx-overlay-s: Main overlay app (run when in VR with: vr-desktop)
    # wayvr-dashboard: Optional GUI for configuration
    # Provided by nixpkgs-xr overlay for latest version
    pkgs.wlx-overlay-s
    pkgs.wayvr-dashboard
    install-mf-codecs
  ];

  # OpenXR runtime configuration for sandboxed applications (Steam)
  # This ensures Steam's FHS environment can locate the OpenXR runtime
  # Respects WiVRn preference when enabled, otherwise uses Monado
  xdg.configFile."openxr/1/active_runtime.json".source =
    if osConfig.host.features.vr.wivrn.enable && osConfig.host.features.vr.wivrn.defaultRuntime then
      "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json"
    else
      "${pkgs.monado}/share/openxr/1/openxr_monado.json";

  # Quest 3 VR Workflow with xrizer (Modern SteamVR Translation)
  #
  # xrizer is a modern replacement for OpenComposite that translates SteamVR games to OpenXR.
  # It works seamlessly with WiVRn and Monado on Wayland/Niri.
  #
  # Usage:
  # 1. In Steam, right-click game (e.g., Half-Life: Alyx)
  # 2. Go to Properties > General > Launch Options
  # 3. Set: xrizer %command%
  # 4. Use Proton-GE as compatibility layer
  #
  # Workflow:
  # 1. Start WiVRn: wivrn-server (or auto-start via systemd)
  # 2. Connect Quest 3: Open WiVRn app on headset
  # 3. Launch games: Use xrizer launch options in Steam
  # 4. Desktop overlay: Run wlx-overlay-s or wayvr-dashboard for Niri window interaction
  #
  # Available Tools (installed system-wide):
  # - xrizer: SteamVR->OpenXR translation (preferred over OpenComposite)
  # - wlx-overlay-s: Desktop overlay (view Niri windows in VR via PipeWire)
  # - wayvr-dashboard: VR Dashboard for Wayland
  # - kaon: UEVR manager (inject VR into flat Unreal Engine games)
  # - vapor: Lightweight VR home/launcher
  # - xrbinder: Controller remapping
  # - lovr: Lua-based VR development
  # - resolute: Resonite mod manager
  # - oscavmgr: OSC Avatar/face tracking manager
  #
  # Note: proton-ge-rtsp-bin is not installed as it's a single binary file
  # If needed for VRChat/Resonite video streams, install as Steam compatibility tool
  #
  # Legacy OpenComposite:
  # For Monado-only setups (without WiVRn), you can still use OpenComposite:
  #   1. Enable: host.features.vr.opencomposite = true;
  #   2. Configure manually via ~/.config/openvr/openvrpaths.vrpath if needed
  # However, xrizer is the modern approach and should be preferred.

  # Shell aliases for VR tools
  programs.zsh.shellAliases = {
    # VR Runtime Logs
    monado-log = "journalctl --user -u monado -f";
    wivrn-log = "journalctl --user -u wivrn -f";

    # Desktop Overlays (view Niri windows in VR)
    vr-desktop = "wlx-overlay-s --show"; # PipeWire-based desktop overlay
    vr-dashboard = "wayvr-dashboard"; # VR Dashboard for Wayland

    # Quest 3 Connection (ADB for sideloading)
    quest-connect = "adb connect"; # Usage: quest-connect 192.168.1.X
    quest-devices = "adb devices";
    quest-shell = "adb shell";
    quest-install = "adb install";
    quest-logs = "adb logcat";

    # VR Development & Tools
    vr-uevr = "kaon"; # UEVR manager (flat-to-VR injection)
    vr-home = "vapor"; # Lightweight VR launcher
    vr-remap = "xrbinder"; # Controller remapping

    # Social VR & Tracking
    vr-resonite-mods = "resolute"; # Resonite mod manager
    vr-osc = "oscavmgr"; # OSC Avatar/face tracking manager

    # Media Foundation codecs for Heresphere
    # Install Media Foundation codecs for a Wine prefix (defaults to ~/.wine)
    # Usage: install-mf-codecs [WINEPREFIX]
    # Example: install-mf-codecs ~/.local/share/wineprefixes/heresphere
    install-mf-codecs = "${install-mf-codecs}/bin/install-mf-codecs";
  };
}
