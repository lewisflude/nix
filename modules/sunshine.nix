# Sunshine game streaming server
# Streams HDMI-A-1 (dummy plug) via KMS capture with NVENC encoding
{ config, ... }:
{
  flake.modules.nixos.sunshine =
    { pkgs, ... }:
    let
      sunshine-prep = pkgs.writeShellApplication {
        name = "sunshine-prep";
        runtimeInputs = [
          pkgs.systemd
          pkgs.coreutils
        ];
        text = ''
          systemd-inhibit --what=idle:sleep \
            --who=sunshine --why="Game streaming" \
            sleep infinity &
          echo $! > "$XDG_RUNTIME_DIR/sunshine-inhibit.pid"
        '';
      };

      sunshine-cleanup = pkgs.writeShellApplication {
        name = "sunshine-cleanup";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
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
          # Capture
          capture = "kms";
          encoder = "nvenc";
          adapter_name = "/dev/dri/renderD128";
          # output_name: set to HDMI-A-1's numeric index after checking logs
          # Run: journalctl --user -u sunshine | grep "Detected monitor"

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

      # NVIDIA encode libraries must be in Sunshine's library path
      systemd.user.services.sunshine.environment = {
        LD_LIBRARY_PATH = "/run/opengl-driver/lib";
      };
    };
}
