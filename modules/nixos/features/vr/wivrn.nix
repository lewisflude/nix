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
  services.wivrn = {
    enable = true;
    package = pkgs.wivrn.override { cudaSupport = true; };
    inherit (cfg.wivrn) autoStart defaultRuntime openFirewall;
    highPriority = cfg.performance; # Enable async reprojection with high priority

    # Steam integration - automatically import OpenXR runtimes
    steam.importOXRRuntimes = true;
    config = {
      enable = true;
      json = {
        # CORRECTED CONFIGURATION - using only officially documented options
        # See: https://github.com/WiVRn/WiVRn/blob/master/docs/configuration.md

        # Encoder configuration optimized for Quest 3 + RTX 4090
        # AV1 provides best compression and quality for Quest 3
        encoder = {
          encoder = "nvenc"; # NVIDIA hardware encoding (RTX 4090)
          codec = "av1"; # AV1 codec (Quest 3 native support)
        };

        # 10-bit color depth for better color reproduction
        # Supported by RTX 4090 NVENC with AV1 codec
        bit-depth = 10;

        # Auto-launch WayVR when headset connects
        # Note: If WayVR fails to start, try removing ~/.config/wayvr
        application = [ pkgs.wayvr ];

        # Optional: Use TCP only (disabled for lower latency)
        # tcp-only = false;

        # Optional: Service discovery via Avahi (enabled by default)
        # publish-service = "avahi";

        # Optional: HID forwarding (keyboard/mouse from headset to PC)
        # Requires uinput kernel module and write access
        # hid-forwarding = false;
      };
    };
  };

  # No systemd override needed - nixpkgs version is up to date

  # Note: VR user tools (wayvr, android-tools, xrizer) are configured in home-manager
  # See: home/nixos/apps/vr.nix

  # Nvidia GPU latency fixes for embedded Monado runtime
  # Addresses present latency issues with Nvidia driver 565+
  # See: https://lvra.gitlab.io/docs/hardware/
  systemd.services.wivrn.environment = {
    XRT_COMPOSITOR_USE_PRESENT_WAIT = "1";
    U_PACING_COMP_TIME_FRACTION_PERCENT = "90";
  };
}
