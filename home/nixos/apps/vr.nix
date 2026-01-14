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

    # GStreamer plugins for wayvr-dashboard media support
    # Required for video playback and media features in the dashboard UI
    pkgs.gst_all_1.gstreamer
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
  ];

  # WayVR systemd service - Auto-start desktop overlay with WiVRn
  # Follows WayVR best practices for OpenXR runtimes (WiVRn/Monado)
  # The overlay will show a home environment with passthrough by default
  systemd.user.services.wayvr = mkIf (osConfig.host.features.vr.wivrn.enable or false) {
    Unit = {
      Description = "WayVR Desktop Overlay for VR";
      Documentation = "https://github.com/wlx-team/wayvr";
      # Start after WiVRn is ready
      After = [ "wivrn.service" ];
      # Bind to WiVRn - stop WayVR when WiVRn stops
      BindsTo = [ "wivrn.service" ];
      # Only start if WiVRn is enabled and running
      ConditionPathExists = "%t/wivrn";
    };

    Service = {
      Type = "simple";
      # OpenXR mode with --show flag (recommended for WiVRn)
      # This shows a home environment with passthrough by default
      ExecStart = "${pkgs.wlx-overlay-s}/bin/wlx-overlay-s --openxr --show";
      Restart = "on-failure";
      RestartSec = "5s";

      # Environment variables
      Environment = [
        # Low-latency PipeWire capture
        "PIPEWIRE_LATENCY=64/48000"
        # Ensure OpenXR runtime is set
        "XR_RUNTIME_JSON=${
          if osConfig.host.features.vr.wivrn.enable && osConfig.host.features.vr.wivrn.defaultRuntime then
            "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json"
          else
            "${pkgs.monado}/share/openxr/1/openxr_monado.json"
        }"
      ];

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
    };

    Install = {
      # Auto-start when WiVRn starts
      WantedBy = [ "wivrn.service" ];
    };
  };

  # DO NOT set XR_RUNTIME_JSON globally - it causes all games to try VR initialization
  # Instead, set it per-game in Steam launch options when you want VR:
  #   XR_RUNTIME_JSON=${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json %command%
  #
  # The active runtime is already set in ~/.config/openxr/1/active_runtime.json
  # by the xdg.configFile below, which is the proper way to configure OpenXR.
  # Setting XR_RUNTIME_JSON globally overrides this and forces VR for all apps.
  #
  # home.sessionVariables.XR_RUNTIME_JSON = ... # REMOVED - DO NOT SET GLOBALLY

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

    # OpenVR paths configuration - Lock to prevent SteamVR from overriding
    # WiVRn v0.23+ should manage this, but we're being explicit to prevent SteamVR interference
    # xrizer MUST be first in the runtime list so Wine/Proton games use it instead of SteamVR
    "openvr/openvrpaths.vrpath" = mkIf (osConfig.host.features.vr.wivrn.enable or false) {
      text = builtins.toJSON {
        config = [
          "${config.home.homeDirectory}/.local/share/Steam/config"
        ];
        external_drivers = null;
        jsonid = "vrpathreg";
        log = [
          "${config.home.homeDirectory}/.local/share/Steam/logs"
        ];
        runtime = [
          # xrizer FIRST - translates OpenVR to OpenXR for WiVRn
          "${pkgs.xrizer}/lib/xrizer"
          # Note: SteamVR intentionally omitted to prevent it from hijacking OpenVR games
        ];
        version = 1;
      };
      force = true;
    };

    # WayVR configuration for optimal WiVRn integration
    # This configures WayVR to work properly with WiVRn's OpenXR runtime
    "wlxoverlay/conf.yaml".text = ''
      # WayVR Configuration
      # Optimized for WiVRn + Quest 3 + Niri

      # PipeWire capture settings
      capture:
        method: pipewire
        rate: 90  # Match Quest 3 refresh rate

      # Display settings
      display:
        show_on_start: false  # Don't auto-show (use double-tap B/Y)

      # Performance optimizations
      performance:
        low_latency: true

      # OpenXR mode (for WiVRn compatibility)
      runtime:
        mode: openxr
        show: false  # Start hidden, show with controller binding
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
  # 1. Start WiVRn: Auto-starts on login (systemctl --user status wivrn)
  # 2. Connect Quest 3: Open WiVRn app on headset
  # 3. Desktop overlay: WayVR auto-starts with WiVRn (double-tap B/Y to show/hide)
  # 4. Launch games: Use launch options above in Steam
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
    wayvr-log = "journalctl --user -u wayvr -f"; # WayVR overlay logs

    # WayVR Service Control (auto-starts with WiVRn by default)
    wayvr-start = "systemctl --user start wayvr"; # Manually start WayVR overlay
    wayvr-stop = "systemctl --user stop wayvr"; # Stop WayVR overlay
    wayvr-restart = "systemctl --user restart wayvr"; # Restart WayVR overlay
    wayvr-status = "systemctl --user status wayvr"; # Check WayVR status

    # Desktop Overlays (view Niri windows in VR)
    # NOTE: WayVR now auto-starts with WiVRn - use these for manual control
    vr-desktop = "PIPEWIRE_LATENCY=64/48000 wlx-overlay-s --show"; # Manual WayVR start (if service disabled)
    vr-desktop-openxr = "PIPEWIRE_LATENCY=64/48000 wlx-overlay-s --openxr --show"; # OpenXR mode with home environment
    vr-dashboard = "wayvr-dashboard"; # Optional management GUI (requires wlx-overlay-s running)

    # VR Audio Control
    # Redirect audio to Quest 3 headset (run while VR app is playing)
    vr-audio-fix = "pactl list sink-inputs short | grep -E 'hlvr|alyx|steam|proton' | awk '{print $1}' | xargs -I {} pactl move-sink-input {} wivrn.sink";
    vr-audio-status = "pactl list sinks short | grep wivrn"; # Check if WiVRn audio device exists

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
