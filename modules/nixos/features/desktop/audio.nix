{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.host.features.media.audio;
in
{
  config = mkIf cfg.enable (mkMerge [
    # Base PipeWire configuration
    {
      # Enable real-time audio support
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;

        # Enable compatibility layers
        alsa = {
          enable = true;
          support32Bit = true; # Required for 32-bit games/applications
        };

        pulse.enable = true; # PulseAudio compatibility

        jack.enable = true; # JACK compatibility

        # WirePlumber session manager configuration
        wireplumber = {
          enable = true;

          # Custom WirePlumber configuration for device priorities and routing
          extraConfig = {
            # Set default device priorities
            "10-device-priorities" = {
              "monitor.alsa.rules" = [
                {
                  matches = [
                    {
                      "node.name" = "~alsa_output.*";
                    }
                  ];
                  actions = {
                    update-props = {
                      "priority.session" = 1000;
                    };
                  };
                }
              ];
            };

            # Bluetooth configuration for better codec support
            # Based on: https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/bluetooth.html
            bluetoothEnhancements = {
              "monitor.bluez.properties" = {
                # Enable high-quality SBC codec
                "bluez5.enable-sbc-xq" = true;

                # Enable mSBC for better headset audio quality
                "bluez5.enable-msbc" = true;

                # Enable hardware volume control
                "bluez5.enable-hw-volume" = true;

                # Support for HSP/HFP profiles (headset/hands-free)
                "bluez5.roles" = [
                  "hsp_hs"
                  "hsp_ag"
                  "hfp_hf"
                  "hfp_ag"
                ];

                # High-quality Bluetooth codecs (when supported by device)
                # Includes: SBC, SBC-XQ, AAC, LDAC (Sony), aptX, aptX HD
                "bluez5.codecs" = [
                  "sbc"
                  "sbc_xq"
                  "aac"
                  "ldac"
                  "aptx"
                  "aptx_hd"
                ];
              };
            };
          };
        };
      };

      # PipeWire environment variables for better gaming/audio experience
      environment.sessionVariables = {
        # SDL2 games: Use PulseAudio backend (PipeWire provides PulseAudio compatibility)
        SDL_AUDIODRIVER = "pulseaudio";

        # PulseAudio buffer latency (60ms is a good balance for gaming)
        PULSE_LATENCY_MSEC = "60";

        # PipeWire-native latency setting (256 frames @ 48kHz = ~5.3ms)
        # This is a good default for most use cases including streaming/recording
        # For ultra-low-latency recording (<2ms), use: pw-metadata -n settings 0 clock.force-quantum 64
        # To reset to default: pw-metadata -n settings 0 clock.force-quantum 0
        PIPEWIRE_LATENCY = "256/48000";

        # Wine/Proton: Use PulseAudio backend (most compatible, works with PipeWire)
        WINE_AUDIO = "pulse";
      };

      # Audio packages needed for PipeWire
      environment.systemPackages = [
        # PipeWire tools
        pkgs.pipewire
        pkgs.wireplumber

        # PulseAudio tools for compatibility
        pkgs.pulseaudio
        pkgs.pavucontrol

        # ALSA utilities
        pkgs.alsa-utils
        pkgs.alsa-tools
      ];
    }

    # musnix real-time audio kernel and optimizations
    (mkIf cfg.realtime {
      musnix = {
        enable = true;

        kernel = {
          realtime = true;
          packages = pkgs.linuxPackages-rt_latest;
        };

        rtirq.enable = true;
      };
    })
  ]);
}
