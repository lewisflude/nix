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

  # Set XR_RUNTIME_JSON environment variable for non-sandboxed VR applications
  # This is required for apps that don't check ~/.config/openxr/1/active_runtime.json
  home.sessionVariables.XR_RUNTIME_JSON =
    if osConfig.host.features.vr.wivrn.enable && osConfig.host.features.vr.wivrn.defaultRuntime then
      "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json"
    else
      "${pkgs.monado}/share/openxr/1/openxr_monado.json";

  xdg.configFile = {
    # OpenXR runtime configuration for sandboxed applications (Steam)
    # This ensures Steam's FHS environment can locate the OpenXR runtime
    # Respects WiVRn preference when enabled, otherwise uses Monado
    "openxr/1/active_runtime.json" = {
      source =
        if osConfig.host.features.vr.wivrn.enable && osConfig.host.features.vr.wivrn.defaultRuntime then
          "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json"
        else
          "${pkgs.monado}/share/openxr/1/openxr_monado.json";
      force = true;
    };

    # Note: OpenVR paths (openvr/openvrpaths.vrpath) are managed automatically by WiVRn v0.23+
    # The openvr-compat-path setting in wivrn.nix tells WiVRn which OpenXR translation layer to use
    # No need for declarative home-manager configuration here

    # WayVR Dashboard configuration for wlx-overlay-s
    # This assigns the dashboard application to WayVR overlay
    "wlxoverlay/wayvr.conf.d/dashboard.yaml".text = ''
      dashboard:
        exec: "${pkgs.wayvr-dashboard}/bin/wayvr-dashboard"
        args: ""
        env: []
    '';
  };

  # Quest 3 VR Workflow with xrizer (2026 Best Practices)
  #
  # xrizer is the modern replacement for OpenComposite, translating SteamVR (OpenVR) games to OpenXR.
  # In 2026, it's the preferred choice for Quest 3 on NixOS with Nvidia and Wayland.
  #
  # Why xrizer?
  # - Performance: Lower overhead for Quest 3's high resolutions (up to 2064x2208 per eye)
  # - Wayland/Nvidia: Better explicit sync and buffer sharing on modern compositors
  # - WiVRn Integration: WiVRn v0.23+ automatically manages openvrpaths.vrpath for xrizer
  #
  # Steam Launch Options:
  #
  # For NATIVE OpenXR games (Half-Life: Alyx, Bonelab):
  #   PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%
  #
  # For SteamVR (OpenVR) games (Beat Saber, Pavlov VR, Google Earth VR):
  #   PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%
  #
  # Note: xrizer is loaded automatically via openvrpaths.vrpath (it's a library, not a command)
  # WiVRn v0.23+ manages this file automatically using the openvr-compat-path setting
  #
  # Note: PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES is handled automatically by
  # services.wivrn.steam.importOXRRuntimes = true in wivrn.nix
  #
  # Workflow:
  # 1. Start WiVRn: Auto-starts on login (or: systemctl --user start wivrn)
  # 2. Connect Quest 3: Open WiVRn app on headset
  # 3. Launch games: Use launch options above in Steam
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
  # WlxOverlay-S in Steam FHS:
  # Due to NixOS's unique filesystem, wlx-overlay-s must be run via steam-run when using SteamVR:
  #   steam-run wlx-overlay-s
  # This is not needed when using WiVRn/Monado directly (OpenXR mode)
  #
  # Legacy OpenComposite:
  # For Monado-only setups (without WiVRn), you can configure OpenComposite manually
  # by setting openvr-compat-path to ${pkgs.opencomposite}/lib/opencomposite instead
  # However, xrizer is the modern approach and should be preferred in 2026.

  # Shell aliases for VR tools
  programs.zsh.shellAliases = {
    # VR Runtime Logs
    monado-log = "journalctl --user -u monado -f";
    wivrn-log = "journalctl --user -u wivrn -f";

    # Desktop Overlays (view Niri windows in VR)
    # Low-latency mode: Reduced capture interval for better responsiveness
    vr-desktop = "PIPEWIRE_LATENCY=64/48000 wlx-overlay-s --show --capture-rate 90"; # PipeWire-based desktop overlay
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
