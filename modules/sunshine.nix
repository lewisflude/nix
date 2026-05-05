# Sunshine game streaming server with NVENC encoding (RTX 4090)
#
# KMS capture streams a virtual 16:9 display on DP-3 (software EDID override).
# NVIDIA's proprietary driver only brings up its KMS modeset pipeline if at
# least one connector reports a real DDC EDID — software EDID injection alone
# isn't enough. A hardware HDMI dummy plug on HDMI-A-1 supplies that signal
# purely at the DRM layer; niri keeps HDMI-A-1 disabled so it never reaches
# the wayland session (see modules/hosts/jupiter/niri-outputs.nix).
#
# Per-stream the prep_cmd swaps the active outputs: DP-1 (the real monitor) is
# disabled and DP-3 is brought up and focused, so sunshine's KMS capture sees
# exactly one active output and `output_name = 0` resolves to DP-3 reliably
# regardless of whether the main monitor is awake at stream time. This is the
# pattern used by Cynary/sunshine-virtual-monitor, niquette.ca's switcher, the
# catwithcode Hyprland headless guide, and Sunshine 6.1's built-in display
# management. Side benefit: the desk monitor blanks while a remote session is
# active. preStart enables DP-3 once so sunshine's startup encoder probe finds
# it; after the probe sunshine sits idle until a client connects.
_: {
  flake.modules.nixos.sunshine =
    { pkgs, config, ... }:
    let
      niri = config.programs.niri.package;

      streamStart = pkgs.writeShellScript "sunshine-stream-start" ''
        ${niri}/bin/niri msg output DP-3 on
        ${niri}/bin/niri msg action focus-monitor DP-3
        ${niri}/bin/niri msg output DP-1 off
      '';

      # Only restore the desktop layout if the real monitor is actually back.
      # If DP-1 is still physically disconnected (user is remote), leave DP-3
      # enabled — otherwise the next Moonlight reconnect would find no KMS
      # outputs and fail with "Couldn't find monitor [0]". When the user
      # returns to the desk and DP-1 reconnects, DP-3 is briefly visible to
      # niri/DMS until manually cleared with `niri msg output DP-3 off`.
      streamEnd = pkgs.writeShellScript "sunshine-stream-end" ''
        if [ "$(cat /sys/class/drm/card1-DP-1/status)" = connected ]; then
          ${niri}/bin/niri msg output DP-1 on
          ${niri}/bin/niri msg action focus-monitor DP-1
          ${niri}/bin/niri msg output DP-3 off
        fi
      '';
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
          # With DP-1 disabled by prep_cmd below, DP-3 is the only KMS output
          # at stream time, so it lands at index 0.
          output_name = 0;

          # Per-stream display swap. The undo only restores the desktop if
          # DP-1 is physically reconnected — when the user is remote the
          # virtual surface stays up so subsequent Moonlight connects work.
          global_prep_cmd = builtins.toJSON [
            {
              do = "${streamStart}";
              undo = "${streamEnd}";
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
