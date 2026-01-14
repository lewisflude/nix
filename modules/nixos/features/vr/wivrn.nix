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
  };
}
