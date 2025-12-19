{
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  vrEnabled = osConfig.host.features.vr.enable or false;
  monadoEnabled = osConfig.host.features.vr.monado or false;
in
lib.mkIf vrEnabled {
  # User VR packages
  home.packages = [
    pkgs.wivrn # Alternative wireless VR (if ALVR doesn't work)
  ];

  # OpenXR environment variable (Monado handles runtime via systemd)
  home.sessionVariables = lib.mkIf monadoEnabled {
    XR_RUNTIME_JSON = "${pkgs.monado}/share/openxr/1/openxr_monado.json";
  };

  # Shell aliases for VR tools
  programs.zsh.shellAliases = {
    # ALVR is now a wrapped command with optimized env vars
    alvr-log = "journalctl --user -u monado -f";

    # Quest ADB shortcuts
    quest-connect = "adb connect"; # Usage: quest-connect 192.168.1.X
    quest-devices = "adb devices";
    quest-shell = "adb shell";
    quest-install = "adb install";
    quest-logs = "adb logcat";
  };
}
