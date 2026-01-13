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
  # WiVRn enables wireless PCVR from Quest headsets over WiFi
  # It wraps Monado and provides network streaming capabilities
  services.wivrn = {
    enable = true;
    inherit (cfg.wivrn) autoStart defaultRuntime openFirewall;
    highPriority = cfg.performance; # Enable async reprojection with high priority

    # Enable CUDA support for NVIDIA GPUs (RTX 4090)
    # This provides hardware-accelerated video encoding for VR streaming
    package = pkgs.wivrn.override { cudaSupport = true; };

    # Monado environment variables for better performance
    monadoEnvironment = lib.mkIf cfg.performance {
      # Minimum time between compositor frames (milliseconds)
      # Lower values reduce latency but increase CPU usage
      # Reduced to 2ms for VR desktop overlay responsiveness
      U_PACING_COMP_MIN_TIME_MS = "2";

      # Exit Monado when all VR applications disconnect
      # Useful for wireless VR to save resources when not in use
      IPC_EXIT_ON_DISCONNECT = if cfg.wivrn.autoStart then "1" else "0";

      # NVIDIA NVENC low-latency encoding (for RTX 4090)
      # Reduces encoding latency for wireless streaming
      WIVRN_ENCODER_PRESET = "p1"; # Ultra low latency preset (was p4)
      WIVRN_ENCODER_RC_MODE = "cbr"; # Constant bitrate for consistent latency
    };
  };
}
