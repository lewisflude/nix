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
    # WayVR (formerly wlx-overlay-s) - Desktop overlay for VR
    # Provided by nixpkgs-xr overlay for latest version
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

  # OpenComposite / OpenVR Compatibility Layer
  # WiVRn v25.8+ automatically manages OpenVR-to-OpenXR translation using Xrizer
  # Manual OpenComposite configuration is no longer needed and has been removed
  #
  # For Monado-only setups (without WiVRn), you can still use OpenComposite if needed:
  #   1. Enable: host.features.vr.opencomposite = true;
  #   2. The OpenComposite package will be installed system-wide
  #   3. Configure manually via ~/.config/openvr/openvrpaths.vrpath if needed
  #
  # Note: Most modern VR applications support OpenXR natively and don't need OpenVR

  # Shell aliases for VR tools
  programs.zsh.shellAliases = {
    # VR logs
    monado-log = "journalctl --user -u monado -f";
    wivrn-log = "journalctl --user -u wivrn -f";

    # Desktop overlay - start WayVR and show working set
    # WayVR automatically detects the correct Wayland display
    vr-desktop = "wayvr --show";

    # Quest ADB shortcuts
    quest-connect = "adb connect"; # Usage: quest-connect 192.168.1.X
    quest-devices = "adb devices";
    quest-shell = "adb shell";
    quest-install = "adb install";
    quest-logs = "adb logcat";

    # Media Foundation codecs for Heresphere
    # Install Media Foundation codecs for a Wine prefix (defaults to ~/.wine)
    # Usage: install-mf-codecs [WINEPREFIX]
    # Example: install-mf-codecs ~/.local/share/wineprefixes/heresphere
    install-mf-codecs = "${install-mf-codecs}/bin/install-mf-codecs";
  };
}
