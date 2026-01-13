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

    # Enable Steam integration
    # Sets PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES to allow Steam to discover WiVRn
    steam.importOXRRuntimes = true;

    # WiVRn Configuration (JSON)
    # Optimized for Quest 3 + RTX 4090
    config = {
      enable = true;
      json = {
        # Encoder configuration (singular, not plural)
        # Can be a string, object, or array for left/right/alpha streams
        encoder = {
          encoder = "nvenc";
          # Quest 3 supports AV1 decoding, RTX 4090 supports AV1 encoding
          codec = "av1";
          # 8-bit color depth (10-bit not supported by current WiVRn/nvenc setup)
          # WiVRn warns: "GPU does not have sufficient support for 10-bit images"
          bit-depth = 8;
        };
        # OpenVR compatibility path:
        # - xrizer: Modern OpenVR reimplementation on OpenXR (default)
        # - OpenComposite: Legacy option (when opencomposite = true)
        # WiVRn configures ~/.config/openvr/openvrpaths.vrpath automatically
        openvr-compat-path = if cfg.opencomposite then "${pkgs.opencomposite}" else "${pkgs.xrizer}";
      };
    };

    # Monado environment variables for better performance
    monadoEnvironment = lib.mkIf cfg.performance {
      # Minimum time between compositor frames (milliseconds)
      # Lower values reduce latency but increase CPU usage
      # Reduced to 2ms for VR desktop overlay responsiveness
      U_PACING_COMP_MIN_TIME_MS = "2";

      # Exit Monado when all VR applications disconnect
      # Useful for wireless VR to save resources when not in use
      IPC_EXIT_ON_DISCONNECT = if cfg.wivrn.autoStart then "1" else "0";
    };
  };
}
