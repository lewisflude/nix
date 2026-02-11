# Sunshine game streaming server
# A custom EDID is loaded at boot to create a persistent virtual display on
# HDMI-A-4, eliminating the need for a physical dummy plug and surviving KVM
# switches. Sunshine captures this output via KMS with NVENC encoding.
# On stream start the ultrawide is disabled; on stream end it is re-enabled.
_: {
  flake.modules.nixos.sunshine =
    { pkgs, ... }:
    let
      # Display output names — verify with: niri msg outputs
      virtualDisplay = "HDMI-A-1"; # 1080p virtual output (EDID-emulated, captured by Sunshine)
      ultrawide = "DP-3"; # AW3423DWF — disabled during streaming

      # 1920x1080@60Hz EDID (v1.3, manufacturer "LNX", sRGB, monitor name "Virtual 1080").
      # Loaded via drm.edid_firmware so the GPU always sees a connected display on
      # the virtual output, even when no physical monitor or dummy plug is attached.
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

      edidFirmware = pkgs.runCommandLocal "edid-virtual-1080p" { } ''
        mkdir -p $out/lib/firmware/edid
        hex="${edidHex}"
        for ((i = 0; i < ''${#hex}; i += 2)); do
          printf "\x''${hex:$i:2}"
        done > $out/lib/firmware/edid/virtual-1080p.bin
      '';

      sunshine-prep = pkgs.writeShellApplication {
        name = "sunshine-prep";
        runtimeInputs = [
          pkgs.systemd
          pkgs.coreutils
          pkgs.niri
        ];
        text = ''
          # Disable ultrawide so the virtual display becomes the sole output
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
          niri msg output "${ultrawide}" on

          pid_file="$XDG_RUNTIME_DIR/sunshine-inhibit.pid"
          if [ -f "$pid_file" ]; then
            kill "$(cat "$pid_file")" 2>/dev/null || true
            rm -f "$pid_file"
          fi
        '';
      };
    in
    {
      # Custom EDID firmware so the GPU always sees a display on the virtual output
      hardware.firmware = [ edidFirmware ];

      # Force the virtual display enabled at boot with our EDID
      boot.kernelParams = [
        "drm.edid_firmware=${virtualDisplay}:edid/virtual-1080p.bin"
        "video=${virtualDisplay}:e"
      ];

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
