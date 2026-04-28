# Sunshine game streaming server with NVENC encoding (RTX 4090)
# KMS capture streams a virtual 16:9 display on DP-3 (EDID override, no dummy plug).
# DP-3 is disabled in niri at startup; sunshine's preStart enables it once via
# `niri msg` so the KMS connector exists when sunshine probes encoders, and the
# global_prep_cmd handles per-stream on/off thereafter.
_: {
  flake.modules.nixos.sunshine =
    { pkgs, config, ... }:
    let
      niri = config.programs.niri.package;
    in
    {
      # Virtual display on DP-3 via EDID override (no physical monitor needed)
      hardware.display.edid.modelines."sun-virt" =
        "173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync";

      hardware.display.outputs."DP-3" = {
        edid = "sun-virt.bin";
        mode = "e"; # force enabled even with nothing plugged in
      };

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
          output_name = 1; # KMS index for DP-3 (sun-virt)

          # Toggle virtual display on/off when a Moonlight client connects/disconnects
          global_prep_cmd = builtins.toJSON [
            {
              do = "${niri}/bin/niri msg output DP-3 on";
              undo = "${niri}/bin/niri msg output DP-3 off";
            }
          ];

          # NVENC (RTX 4090)
          nvenc_preset = 3;
          nvenc_rc = "cbr";
          nvenc_twopass = "quarter_res";
          nvenc_spatial_aq = 1;
          nvenc_temporal_aq = 1;
          bitrate = 20000;

          # Audio
          audio_codec = "opus";
          channels = 2;
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
        # Enable the virtual output before sunshine probes encoders. Globs for
        # the niri socket since NIRI_SOCKET isn't inherited by user services.
        preStart = ''
          for sock in "$XDG_RUNTIME_DIR"/niri.wayland-1.*.sock; do
            [ -S "$sock" ] || continue
            NIRI_SOCKET="$sock" ${niri}/bin/niri msg output DP-3 on || true
            break
          done
        '';
      };
    };
}
