{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    ;
  cfg = config.host.features.media.audio;
in
{
  config = mkIf cfg.enable (mkMerge [
    # Base PipeWire configuration
    {
      services.pipewire = {
        enable = true;

        # Enable compatibility layers
        alsa = {
          enable = true;
          support32Bit = true; # Required for 32-bit games/applications
        };

        pulse.enable = true; # PulseAudio compatibility

        # JACK compatibility for professional audio applications (Ardour, REAPER, etc.)
        jack.enable = true;

        # Low-latency configuration optimized for gaming and real-time audio
        extraConfig.pipewire."99-lowlatency" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 256; # ~5.3ms latency at 48kHz
            "default.clock.min-quantum" = 64; # ~1.3ms minimum
            "default.clock.max-quantum" = 2048; # ~42ms maximum
            "default.clock.allowed-rates" = [
              44100
              48000
              96000
              192000
            ];
          };
          # Load filter chain modules for audio processing
          "context.modules" = [
            {
              name = "libpipewire-module-filter-chain";
              args = { };
            }
          ];
        };

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
            "11-bluetooth-policy" = {
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
                # Includes: SBC, SBC-XQ, AAC, LDAC (Sony), aptX, aptX HD, aptX LL, LC3 (LE Audio)
                "bluez5.codecs" = [
                  "sbc"
                  "sbc_xq"
                  "aac"
                  "ldac"
                  "aptx"
                  "aptx_hd"
                  "aptx_ll" # Low Latency variant
                  "lc3" # Bluetooth LE Audio codec
                ];

                # LDAC quality settings (high quality, adaptive bitrate)
                # Quality presets: hq (990kbps), sq (660kbps), mq (330kbps)
                "bluez5.default.rate" = 48000;
                "bluez5.default.channels" = 2;
              };

              # LDAC encoding quality for A2DP streaming
              "bluez5.a2dp.ldac.quality" = "hq"; # High Quality mode (990kbps)
            };

            # Disable audio device suspension to prevent audio dropouts
            "51-disable-suspension" = {
              "monitor.alsa.rules" = [
                {
                  matches = [
                    {
                      "node.name" = "~alsa_input.*";
                    }
                    {
                      "node.name" = "~alsa_output.*";
                    }
                  ];
                  actions = {
                    update-props = {
                      "session.suspend-timeout-seconds" = 0;
                    };
                  };
                }
              ];
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

      # Audio utilities (PipeWire and WirePlumber are automatically installed by the service)
      environment.systemPackages = [
        # PulseAudio tools for compatibility
        pkgs.pulseaudio

        # ALSA utilities
        pkgs.alsa-utils
        pkgs.alsa-tools
      ];

      # USB audio optimizations
      # Disable USB autosuspend for audio devices to prevent dropouts
      services.udev.extraRules = ''
        # Disable autosuspend for USB audio interfaces
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idClass}=="01", TEST=="power/control", ATTR{power/control}="on"
      '';

      # Assertions to ensure proper configuration
      assertions = [
        {
          assertion = cfg.noiseCancellation -> cfg.enable;
          message = "Noise cancellation requires audio.enable to be true";
        }
        {
          assertion = cfg.echoCancellation -> cfg.enable;
          message = "Echo cancellation requires audio.enable to be true";
        }
      ];
    }

    # Noise cancellation filter (RNNoise)
    # Useful for voice chat, calls, and content creation
    (mkIf cfg.noiseCancellation {
      services.pipewire.extraConfig.pipewire."99-input-denoising" = {
        "context.modules" = [
          {
            name = "libpipewire-module-filter-chain";
            args = {
              "node.description" = "Noise Canceling Source";
              "media.name" = "Noise Canceling Source";
              "filter.graph" = {
                nodes = [
                  {
                    type = "ladspa";
                    name = "rnnoise";
                    plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                    label = "noise_suppressor_stereo";
                    control = {
                      "VAD Threshold (%)" = 50.0;
                      "VAD Grace Period (ms)" = 200;
                      "Retroactive VAD Grace (ms)" = 0;
                    };
                  }
                ];
              };
              "audio.position" = [
                "FL"
                "FR"
              ];
              "capture.props" = {
                "node.name" = "capture.rnnoise_source";
                "node.passive" = true;
                "audio.rate" = 48000;
              };
              "playback.props" = {
                "node.name" = "rnnoise_source";
                "media.class" = "Audio/Source";
                "audio.rate" = 48000;
              };
            };
          }
        ];
      };

      # Add rnnoise-plugin package for noise cancellation
      environment.systemPackages = [ pkgs.rnnoise-plugin ];
    })

    # Echo cancellation filter (WebRTC)
    # Useful for calls, streaming, and recording
    (mkIf cfg.echoCancellation {
      services.pipewire.extraConfig.pipewire."99-echo-cancel" = {
        "context.modules" = [
          {
            name = "libpipewire-module-echo-cancel";
            args = {
              "node.description" = "Echo Cancellation";
              "capture.props" = {
                "node.name" = "echo-cancel-capture";
                "node.passive" = true;
              };
              "source.props" = {
                "node.name" = "echo-cancel-source";
                "media.class" = "Audio/Source";
              };
              "sink.props" = {
                "node.name" = "echo-cancel-sink";
                "media.class" = "Audio/Sink";
              };
              "aec.method" = "webrtc"; # Use WebRTC echo cancellation
              "aec.args" = {
                # WebRTC echo cancellation settings
                "webrtc.gain_control" = true; # Automatic gain control
                "webrtc.extended_filter" = true; # Better echo suppression
                "webrtc.delay_agnostic" = true; # Handle varying delays
                "webrtc.noise_suppression" = true; # Additional noise reduction
                "webrtc.high_pass_filter" = true; # Remove low-frequency noise
              };
            };
          }
        ];
      };
    })
  ]);
}
