# Sunshine game streaming server
# Streams dummy plug (1080p HDMI) via KMS capture with NVENC encoding.
# On stream start, the ultrawide is disabled so games launch on the dummy plug.
# On stream end, the ultrawide is re-enabled.
{ ... }:
{
  flake.modules.nixos.sunshine =
    { pkgs, ... }:
    let
      # Display output names — verify with: niri msg outputs
      # Dummy plug: HDMI-A-4 (1080p, always active, captured by Sunshine)
      ultrawide = "DP-3"; # AW3423DWF — disabled during streaming

      sunshine-prep = pkgs.writeShellApplication {
        name = "sunshine-prep";
        runtimeInputs = [
          pkgs.systemd
          pkgs.coreutils
          pkgs.niri
        ];
        text = ''
          # Disable ultrawide so the dummy plug becomes the sole display
          niri msg output "${ultrawide}" off
          sleep 1

          # Inhibit system sleep for the duration of the stream
          systemd-inhibit --what=idle:sleep \
            --who=sunshine --why="Game streaming" \
            sleep infinity &
          echo $! > "$XDG_RUNTIME_DIR/sunshine-inhibit.pid"
        '';
      };

      sunshine-cleanup = pkgs.writeShellApplication {
        name = "sunshine-cleanup";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.niri
        ];
        text = ''
          # Re-enable ultrawide
          niri msg output "${ultrawide}" on

          # Stop sleep inhibitor
          pid_file="$XDG_RUNTIME_DIR/sunshine-inhibit.pid"
          if [ -f "$pid_file" ]; then
            kill "$(cat "$pid_file")" 2>/dev/null || true
            rm -f "$pid_file"
          fi
        '';
      };
    in
    {
      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
        package = pkgs.sunshine.override { cudaSupport = true; };

        settings = {
          # Capture — KMS grabs the dummy plug by output index.
          # Find the correct index: journalctl --user -u sunshine | grep -i monitor
          capture = "kms";
          encoder = "nvenc";
          adapter_name = "/dev/dri/renderD128";
          output_name = 0;

          # NVENC encoding (RTX 4090)
          nvenc_preset = 1;
          nvenc_rc = "cbr";
          nvenc_twopass = "quarter_res";
          nvenc_spatial_aq = 1;
          nvenc_temporal_aq = 1;
          bitrate = 20000;
          qp = 28;
          sw_preset = "ultrafast";

          # Audio
          audio_codec = "opus";
          channels = 2;
          audio_bitrate = 128;
        };

        applications.apps = [
          {
            name = "Desktop";
            prep-cmd = [
              {
                do = "${sunshine-prep}/bin/sunshine-prep";
                undo = "${sunshine-cleanup}/bin/sunshine-cleanup";
              }
            ];
          }
        ];
      };

      # Sunshine needs WAYLAND_DISPLAY to reach Niri, and NVIDIA libs for encoding
      systemd.user.services.sunshine.environment = {
        LD_LIBRARY_PATH = "/run/opengl-driver/lib";
        WAYLAND_DISPLAY = "wayland-1";
      };
    };
}
