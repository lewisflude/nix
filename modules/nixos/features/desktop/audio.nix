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

        # Low-latency configuration
        # Ultra-low latency: 64 frames @ 48kHz = ~1.3ms (for professional recording/monitoring)
        # Balanced latency: 256 frames @ 48kHz = ~5.3ms (for general use, streaming, gaming)
        extraConfig.pipewire."99-lowlatency" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = if cfg.ultraLowLatency then 64 else 256;
            "default.clock.min-quantum" = 64; # ~1.3ms minimum for pro audio
            "default.clock.max-quantum" = 2048; # ~42ms maximum for power saving
            "default.clock.allowed-rates" = [
              44100
              48000
              96000
              192000
            ];
          };
        };

        # Provide a consumer-friendly stereo sink that still routes into the
        # Apogee device so Proton titles see predictable formats.
        extraConfig.pipewire."90-proton-stereo" = {
          "context.modules" = [
            {
              name = "libpipewire-module-filter-chain";
              args = {
                "node.description" = "Proton Stereo Bridge";
                "node.name" = "proton_stereo_bridge";
                "media.class" = "Audio/Sink";
                "audio.position" = [
                  "FL"
                  "FR"
                ];
                "filter.graph" = {
                  "nodes" = [
                    {
                      "type" = "builtin";
                      "name" = "copy";
                      "label" = "copy";
                    }
                  ];
                };
                "capture.props" = {
                  "node.name" = "proton_stereo_bridge.capture";
                  "audio.rate" = 48000;
                  "audio.channels" = 2;
                  "audio.format" = "S16LE";
                  "audio.position" = [
                    "FL"
                    "FR"
                  ];
                };
                "playback.props" = {
                  "node.name" = "proton_stereo_bridge.playback";
                  "audio.rate" = 48000;
                  "audio.channels" = 2;
                  "audio.format" = "S32LE";
                  "audio.position" = [
                    "FL"
                    "FR"
                  ];
                };
              };
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

            # Proton routing: direct Proton/Steam audio into the stereo bridge so
            # games never interact with the multi-channel pro-audio sink directly.
            "90-proton-routing" = {
              "monitor.rules" = [
                {
                  matches = [
                    {
                      "node.name" = "proton_stereo_bridge";
                    }
                  ];
                  actions = {
                    update-props = {
                      "priority.session" = 1900;
                    };
                  };
                }
              ];

              "monitor.stream.rules" = [
                {
                  matches = [
                    {
                      "application.process.binary" = "steam";
                    }
                    {
                      "application.name" = "~steam_app_.*";
                    }
                    {
                      "application.name" = "Steam";
                    }
                  ];
                  actions = {
                    update-props = {
                      "node.target" = "proton_stereo_bridge";
                      "node.latency" = "256/48000";
                      "session.suspend-timeout-seconds" = 0;
                    };
                  };
                }
                {
                  matches = [
                    {
                      "application.id" = "gamescope";
                    }
                  ];
                  actions = {
                    update-props = {
                      "node.target" = "proton_stereo_bridge";
                      "node.latency" = "256/48000";
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

        # PipeWire-native latency setting
        # Ultra-low latency: 64/48000 (~1.3ms) for professional recording/monitoring
        # Balanced latency: 256/48000 (~5.3ms) for general use, streaming, gaming
        # Manual override: pw-metadata -n settings 0 clock.force-quantum <frames>
        # Reset to default: pw-metadata -n settings 0 clock.force-quantum 0
        PIPEWIRE_LATENCY = if cfg.ultraLowLatency then "64/48000" else "256/48000";

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
      # Critical for professional USB audio interfaces like Apogee Symphony Desktop
      services.udev.extraRules = ''
        # Disable autosuspend for USB audio interfaces (class 01)
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idClass}=="01", TEST=="power/control", ATTR{power/control}="on"

        # Set realtime priority for USB audio devices
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idClass}=="01", ATTR{power/wakeup}="disabled"

        # Apogee-specific optimizations (if detected)
        # Apogee Symphony Desktop (USB Vendor ID: 0xa07, Product ID varies)
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0a07", ATTR{power/control}="on", ATTR{power/wakeup}="disabled"
      '';

      # USB audio-specific kernel parameters (when USB audio interface is enabled)
      boot.kernelParams = lib.optionals cfg.usbAudioInterface.enable [
        # Increase USB polling rate for lower latency
        "usbcore.autosuspend=-1" # Disable USB autosuspend globally for audio work
      ];

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
