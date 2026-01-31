# WiVRn Wireless VR Streaming Configuration
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
in
lib.mkIf (cfg.enable && cfg.wivrn.enable) {
  # WiVRn wireless VR streaming configuration
  # Provides wireless PCVR from Quest headsets over WiFi using embedded Monado runtime
  # Following LVRA best practices: use defaults for best out-of-the-box performance
  services.wivrn = {
    enable = true;
    package = pkgs.wivrn.override { cudaSupport = true; }; # Essential for RTX 4090
    inherit (cfg.wivrn) autoStart defaultRuntime openFirewall;
    highPriority = cfg.performance; # Enable async reprojection with high priority

    # Steam integration - automatically import OpenXR runtimes
    steam.importOXRRuntimes = true;
    config = {
      enable = true;
      json = {
        # WiVRn auto-detects optimal encoder settings based on hardware
        # RTX 4090 will automatically use NVENC with AV1 codec at 10-bit depth
        # Quest 3 hardware is automatically detected and optimized

        # Auto-launch WayVR when headset connects
        application = [ pkgs.wayvr ];
      };
    };
  };

  # NVIDIA GPU latency fixes for embedded Monado runtime
  # Addresses present latency issues with Nvidia driver 565+
  # See: https://lvra.gitlab.io/docs/hardware/
  systemd.services.wivrn.environment = {
    XRT_COMPOSITOR_USE_PRESENT_WAIT = "1";
    U_PACING_COMP_TIME_FRACTION_PERCENT = "90";
  };
}
