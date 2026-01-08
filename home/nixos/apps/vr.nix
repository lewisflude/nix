{
  lib,
  pkgs,
  config,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;
  vrEnabled = osConfig.host.features.vr.enable or false;
  opencompositeEnabled = osConfig.host.features.vr.opencomposite or false;

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
  home.packages = [
    pkgs.wlx-overlay-s
    install-mf-codecs
  ];

  # OpenComposite configuration
  # Allows OpenVR games (including SteamVR) to run on OpenXR runtimes (Monado/WiVRn)
  # Stored as .vrpath.nix - use 'vr-enable' alias to activate, 'vr-disable' to deactivate
  # This prevents conflicts with Steam Link and other non-VR Steam features
  xdg.configFile."openvr/openvrpaths.vrpath.nix" = mkIf opencompositeEnabled {
    text = ''
      {
        "config" :
        [
          "${config.xdg.dataHome}/Steam/config"
        ],
        "external_drivers" : null,
        "jsonid" : "vrpathreg",
        "log" :
        [
          "${config.xdg.dataHome}/Steam/logs"
        ],
        "runtime" :
        [
          "${pkgs.opencomposite}/lib/opencomposite"
        ],
        "version" : 1
      }
    '';
  };

  # Shell aliases for VR tools
  programs.zsh.shellAliases = {
    # VR logs
    wivrn-log = "journalctl --user -u wivrn -f";

    # Quest ADB shortcuts
    quest-connect = "adb connect"; # Usage: quest-connect 192.168.1.X
    quest-devices = "adb devices";
    quest-shell = "adb shell";
    quest-install = "adb install";
    quest-logs = "adb logcat";

    # OpenComposite toggle (for playing OpenVR games on Monado)
    # Disable when using Steam Link or non-VR Steam features
    vr-enable = "ln -sf ${config.xdg.configHome}/openvr/openvrpaths.vrpath.nix ${config.xdg.configHome}/openvr/openvrpaths.vrpath";
    vr-disable = "rm -f ${config.xdg.configHome}/openvr/openvrpaths.vrpath";

    # Media Foundation codecs for Heresphere
    # Install Media Foundation codecs for a Wine prefix (defaults to ~/.wine)
    # Usage: install-mf-codecs [WINEPREFIX]
    # Example: install-mf-codecs ~/.local/share/wineprefixes/heresphere
    install-mf-codecs = "${install-mf-codecs}/bin/install-mf-codecs";
  };
}
