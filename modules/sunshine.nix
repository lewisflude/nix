# Sunshine game streaming server
# A custom EDID is loaded at boot to create a persistent virtual display on
# HDMI-A-1, eliminating the need for a physical dummy plug and surviving KVM
# switches. Sunshine captures this output via KMS with NVENC encoding.
# HDMI-A-1 is kept off by default (see niri.nix) and only enabled during
# active streams to prevent the mouse cursor escaping to it during gaming.
_: {
  flake.modules.nixos.sunshine =
    { pkgs, ... }:
    let
      # Display output names — verify with: niri msg outputs
      virtualDisplay = "HDMI-A-1"; # 1080p virtual output (EDID-emulated, captured by Sunshine)
      ultrawide = "DP-1"; # AW3423DWF — disabled during streaming

      # Auto-discover the niri IPC socket (path contains the PID, so it's dynamic)
      findNiriSocket = ''
        if [ -z "''${NIRI_SOCKET:-}" ]; then
          NIRI_SOCKET="$(find "/run/user/$(id -u)" -maxdepth 1 -name 'niri.*.sock' -print -quit 2>/dev/null || true)"
          export NIRI_SOCKET
        fi
      '';

      niriDeps = [
        pkgs.coreutils
        pkgs.findutils
        pkgs.niri
      ];

      sunshine-prep = pkgs.writeShellApplication {
        name = "sunshine-prep";
        runtimeInputs = niriDeps ++ [ pkgs.systemd ];
        text = ''
          ${findNiriSocket}

          # Enable virtual display and disable ultrawide so it becomes the sole output
          niri msg output "${virtualDisplay}" on
          niri msg output "${ultrawide}" off || true
          sleep 1

          # Match virtual display resolution to the Moonlight client
          width="''${SUNSHINE_CLIENT_WIDTH:-1920}"
          height="''${SUNSHINE_CLIENT_HEIGHT:-1080}"
          fps="''${SUNSHINE_CLIENT_FPS:-60}"
          niri msg output "${virtualDisplay}" mode "''${width}x''${height}@''${fps}" || true

          # Inhibit system sleep for the duration of the stream
          systemd-inhibit --what=idle:sleep \
            --who=sunshine --why="Game streaming" \
            sleep infinity &
          echo $! > "$XDG_RUNTIME_DIR/sunshine-inhibit.pid"
        '';
      };

      sunshine-cleanup = pkgs.writeShellApplication {
        name = "sunshine-cleanup";
        runtimeInputs = niriDeps;
        text = ''
          ${findNiriSocket}

          # Restore ultrawide and disable virtual display
          # sunshine-prep will re-enable it on the next stream connection
          niri msg output "${ultrawide}" on || true
          niri msg output "${virtualDisplay}" off || true

          pid_file="$XDG_RUNTIME_DIR/sunshine-inhibit.pid"
          if [ -f "$pid_file" ]; then
            kill "$(cat "$pid_file")" 2>/dev/null || true
            rm -f "$pid_file"
          fi
        '';
      };
    in
    {
      # 1920x1080@60Hz EDID generated from modeline so the GPU always sees a
      # display on the virtual output, force-enabled at boot
      hardware.display.edid.modelines."virt-1080p" =
        "148.50  1920 2008 2052 2200  1080 1084 1089 1125  +hsync +vsync";
      hardware.display.outputs.${virtualDisplay} = {
        edid = "virt-1080p.bin";
        mode = "e";
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
          # KMS capture on the virtual display.
          # Find the correct output index: journalctl --user -u sunshine | grep -i monitor
          capture = "kms";
          encoder = "nvenc";
          adapter_name = "/dev/dri/card1";
          output_name = 0;

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

          # Force Xbox 360 controller emulation for reliable Steam detection.
          # Default "auto" can select DS4/DS5/Switch types that Steam Input
          # doesn't reliably recognise as virtual uinput devices on Linux.
          gamepad = "x360";
        };

        applications.apps =
          let
            streamPrep = {
              do = "${sunshine-prep}/bin/sunshine-prep";
              undo = "${sunshine-cleanup}/bin/sunshine-cleanup";
            };
          in
          [
            {
              name = "Desktop";
              prep-cmd = [ streamPrep ];
            }
            {
              name = "Steam Big Picture";
              detached = [ "setsid steam steam://open/bigpicture" ];
              prep-cmd = [
                streamPrep
                {
                  do = "";
                  undo = "setsid steam steam://close/bigpicture";
                }
              ];
            }
          ];
      };

      # Sunshine needs WAYLAND_DISPLAY to reach Niri, and NVIDIA libs for encoding.
      # Virtual display is enabled per-connection by sunshine-prep and disabled
      # after streaming by sunshine-cleanup, keeping HDMI-A-1 off when not
      # streaming so the mouse cursor can't escape to it during gaming.
      systemd.user.services.sunshine = {
        after = [ "graphical-session.target" ];
        environment = {
          LD_LIBRARY_PATH = "/run/opengl-driver/lib";
          WAYLAND_DISPLAY = "wayland-1";
        };
      };
    };
}
