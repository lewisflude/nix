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
in
mkIf vrEnabled {
  # User VR packages
  home.packages = [ pkgs.wlx-overlay-s ];

  # OpenComposite configuration
  # Allows OpenVR games (including SteamVR) to run on OpenXR runtimes (Monado/WiVRn)
  # Force = true prevents Steam from overwriting this file with SteamVR paths
  xdg.configFile."openvr/openvrpaths.vrpath" = mkIf opencompositeEnabled {
    force = true; # Prevent Steam from reverting to SteamVR
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
  };
}
