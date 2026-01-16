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

    # Steam integration - allows Steam to auto-discover WiVRn as OpenXR runtime
    # Sets PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1 system-wide
    steam.importOXRRuntimes = true;

    # WiVRn configuration
    config = {
      enable = true;
      json = {
        # Auto-start WayVR desktop overlay (package only, no args)
        # Testing if module works without arguments
        application = pkgs.wayvr;

        # RTX 4090 optimizations
        bitrate = 150000000; # 150 Mbps - explicit quality target for WiFi 6

        # Enable keyboard/mouse input forwarding for WayVR desktop use
        hid-forwarding = true;

        # Encoder/codec auto-detection works well:
        # - RTX 4090 → nvenc encoder detected
        # - Quest 3 + RTX 4090 → AV1 codec selected (best quality/bandwidth)
        # - 8-bit depth (Quest 3 has 8-bit OLED panels)
      };
    };
  };

  # Fix: Remove --systemd flag that the current WiVRn version doesn't support
  # The NixOS module adds this flag but wivrn-server doesn't recognize it
  # We override the ExecStart to remove --systemd while keeping the config file
  systemd.user.services.wivrn.serviceConfig.ExecStart = lib.mkForce [
    "" # Clear the default ExecStart
    "/run/wrappers/bin/wivrn-server -f ${pkgs.writeText "wivrn-config.json" (builtins.toJSON config.services.wivrn.config.json)}"
  ];

  # System packages for WiVRn
  environment.systemPackages = [
    pkgs.wayvr # Desktop overlay for VR

    # ADB for wired VR fallback (USB connection when WiFi is unstable)
    # systemd 258+ handles udev rules automatically, no need for programs.adb
    pkgs.android-tools
  ];
}
