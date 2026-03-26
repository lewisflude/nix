# Sunshine game streaming server with NVENC encoding (RTX 4090)
# KMS capture streams HDMI-A-1 output — enabled on connect, disabled on disconnect.
# Kernel EDID override forces HDMI-A-1 as "connected" without a physical display.
# Niri keeps the output off by default; Sunshine prep-cmd toggles it via IPC.
_: {
  flake.modules.nixos.sunshine =
    { pkgs, ... }:
    {
      # Force HDMI-A-1 connected via EDID override (no dummy plug needed)
      hardware.display.edid.modelines."sunshine-1080p" =
        "173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync";

      boot.kernelParams = [
        "drm.edid_firmware=HDMI-A-1:edid/sunshine-1080p.bin"
        "video=HDMI-A-1:e"
      ];

      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
        package = pkgs.sunshine.override {
          cudaSupport = true;
          boost = pkgs.boost186; # boost 1.87+ breaks sunshine build (nixpkgs#375077)
        };

        settings = {
          capture = "kms";
          encoder = "nvenc";
          adapter_name = "/dev/dri/card1";
          output_name = "HDMI-A-1";

          # Toggle HDMI-A-1 on stream connect/disconnect (niri IPC)
          global_prep_cmd = ''[{"do":"niri msg output HDMI-A-1 on","undo":"niri msg output HDMI-A-1 off"}]'';

          # NVENC (RTX 4090)
          nvenc_preset = 3;
          nvenc_rc = "cbr";
          nvenc_twopass = "quarter_res";
          nvenc_spatial_aq = 1;
          nvenc_temporal_aq = 1;
          bitrate = 20000;

          # Audio
          audio_codec = "opus";
          channels = 6;
          audio_bitrate = 192;

          gamepad = "x360";
        };
      };

      systemd.user.services.sunshine = {
        after = [ "graphical-session.target" ];
        environment = {
          LD_LIBRARY_PATH = "/run/opengl-driver/lib";
          WAYLAND_DISPLAY = "wayland-1";
        };
      };
    };
}
