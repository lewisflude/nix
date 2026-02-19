# Sunshine game streaming server
# A custom EDID is loaded at boot to create a persistent virtual display on
# HDMI-A-1, eliminating the need for a physical dummy plug and surviving KVM
# switches. Sunshine captures this output via KMS with NVENC encoding.
# On stream start the ultrawide is disabled; on stream end it is re-enabled.
_: {
  flake.modules.nixos.sunshine =
    { pkgs, ... }:
    let
      # Display output names — verify with: niri msg outputs
      virtualDisplay = "HDMI-A-1"; # 1080p virtual output (EDID-emulated, captured by Sunshine)
      ultrawide = "DP-1"; # AW3423DWF — disabled during streaming

      # 1920x1080@60Hz EDID (v1.3, manufacturer "LNX", sRGB, monitor name "Virtual 1080").
      # Loaded via hardware.display.edid so the GPU always sees a connected display
      # on the virtual output, even when no physical monitor or dummy plug is attached.
      edidHex = builtins.concatStringsSep "" [
        "00FFFFFFFFFFFF00" # Header
        "31D8000000000000" # Manufacturer "LNX", product 0, serial 0
        "0122010380351E78" # Week 1, 2024, EDID 1.3, digital, 53x30 cm, gamma 2.2
        "0AEE91A3544C9926" # sRGB chromaticity
        "0F50540000000101" # Established/standard timings (unused)
        "0101010101010101"
        "010101010101023A" # DTD: pixel clock 148.5 MHz (1920x1080@60Hz)
        "801871382D40582C" # H-active 1920, H-blank 280, V-active 1080, V-blank 45
        "4500122C2100001E" # Sync 88/44 + 4/5, 530x300 mm, +H/+V
        "000000FD00324B1E" # Range limits: 50-75 Hz V, 30-81 kHz H
        "5110000A20202020" # Max pixel clock 160 MHz
        "2020000000FC0056" # Monitor name: "Virtual 1080"
        "69727475616C2031"
        "3038300A00000010" # Dummy descriptor
        "0000000000000000"
        "0000000000000064" # Extension count 0, checksum 0x64
      ];

      edidPackage = pkgs.runCommandLocal "edid-virtual-1080p" { } ''
        mkdir -p $out/lib/firmware/edid
        hex="${edidHex}"
        for ((i = 0; i < ''${#hex}; i += 2)); do
          printf "\x''${hex:$i:2}"
        done > $out/lib/firmware/edid/virtual-1080p.bin
      '';

      # Auto-discover the niri IPC socket (path contains the PID, so it's dynamic)
      findNiriSocket = ''
        if [ -z "''${NIRI_SOCKET:-}" ]; then
          NIRI_SOCKET="$(find "/run/user/$(id -u)" -maxdepth 1 -name 'niri.*.sock' -print -quit 2>/dev/null || true)"
          export NIRI_SOCKET
        fi
      '';

      sunshine-enable-display = pkgs.writeShellApplication {
        name = "sunshine-enable-display";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.niri
        ];
        text = ''
          ${findNiriSocket}
          if [ -z "''${NIRI_SOCKET:-}" ]; then
            echo "Warning: niri socket not found, cannot enable virtual display" >&2
            exit 0
          fi
          niri msg output "${virtualDisplay}" on || true
          sleep 1
        '';
      };

      sunshine-prep = pkgs.writeShellApplication {
        name = "sunshine-prep";
        runtimeInputs = [
          pkgs.systemd
          pkgs.coreutils
          pkgs.findutils
          pkgs.niri
        ];
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
        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.niri
        ];
        text = ''
          ${findNiriSocket}

          # Reset virtual display resolution and restore ultrawide
          # Keep the virtual display ON so Sunshine's KMS capture remains valid
          # for future connections (turning it off invalidates the CRTC handle)
          niri msg output "${virtualDisplay}" mode 1920x1080@60 || true
          niri msg output "${ultrawide}" on || true

          pid_file="$XDG_RUNTIME_DIR/sunshine-inhibit.pid"
          if [ -f "$pid_file" ]; then
            kill "$(cat "$pid_file")" 2>/dev/null || true
            rm -f "$pid_file"
          fi
        '';
      };
    in
    {
      # Custom EDID firmware so the GPU always sees a display on the virtual output,
      # force-enabled at boot via hardware.display.outputs
      hardware.display.edid.packages = [ edidPackage ];
      hardware.display.outputs.${virtualDisplay} = {
        edid = "virtual-1080p.bin";
        mode = "e";
      };

      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
        package = pkgs.sunshine.override { cudaSupport = true; };

        settings = {
          # KMS capture on the virtual display.
          # Find the correct output index: journalctl --user -u sunshine | grep -i monitor
          capture = "kms";
          encoder = "nvenc";
          adapter_name = "/dev/dri/card1";
          output_name = 0;

          # NVENC (RTX 4090)
          nvenc_preset = 1;
          nvenc_rc = "cbr";
          nvenc_twopass = "quarter_res";
          nvenc_spatial_aq = 1;
          nvenc_temporal_aq = 1;
          bitrate = 20000;

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
          {
            name = "Steam Big Picture";
            detached = [ "setsid steam steam://open/bigpicture" ];
            prep-cmd = [
              {
                do = "${sunshine-prep}/bin/sunshine-prep";
                undo = "${sunshine-cleanup}/bin/sunshine-cleanup";
              }
              {
                do = "";
                undo = "setsid steam steam://close/bigpicture";
              }
            ];
          }
        ];
      };

      # Sunshine needs WAYLAND_DISPLAY to reach Niri, and NVIDIA libs for encoding.
      # ExecStartPre enables the virtual display so Sunshine's encoder probe finds
      # an active CRTC even when the KVM is switched away (DP-1 disconnected).
      systemd.user.services.sunshine = {
        after = [ "graphical-session.target" ];
        environment = {
          LD_LIBRARY_PATH = "/run/opengl-driver/lib";
          WAYLAND_DISPLAY = "wayland-1";
        };
        serviceConfig.ExecStartPre = "${sunshine-enable-display}/bin/sunshine-enable-display";
      };
    };
}
