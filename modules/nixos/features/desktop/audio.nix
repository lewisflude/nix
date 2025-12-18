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

  # Audio configuration constants
  quantum = if cfg.ultraLowLatency then 64 else 256;
  latency = "${toString quantum}/48000";
in
{
  config = mkIf cfg.enable (mkMerge [
    # Base PipeWire configuration
    {
      # Enable realtime scheduling for PipeWire
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;

        # Compatibility layers for legacy audio APIs
        alsa = {
          enable = true;
          support32Bit = true; # Required for 32-bit games
        };
        pulse.enable = true; # PulseAudio compatibility
        jack.enable = true; # JACK for professional audio (Ardour, REAPER, etc.)

        # Combined PipeWire extraConfig - low-latency settings and gaming bridge
        extraConfig = {
          # Low-latency configuration for PipeWire core
          pipewire."92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = quantum;
              "default.clock.min-quantum" = 64;
              "default.clock.max-quantum" = 2048;
            };
            "context.modules" = [
              {
                name = "libpipewire-module-rt";
                args = {
                  "nice.level" = -11;
                  "rt.prio" = 88;
                  "rt.time.soft" = 200000;
                  "rt.time.hard" = 200000;
                };
                flags = [
                  "ifexists"
                  "nofail"
                ];
              }
            ];
          };

          # Low-latency configuration for PulseAudio backend
          # Note: libpipewire-module-protocol-pulse is already loaded by the base
          # pipewire-pulse.conf when services.pipewire.pulse.enable = true
          # We only need to configure the pulse properties here
          pipewire-pulse."92-low-latency" = {
            "pulse.properties" = {
              "pulse.min.req" = latency;
              "pulse.default.req" = latency;
              "pulse.max.req" = latency;
              "pulse.min.quantum" = latency;
              "pulse.max.quantum" = latency;
            };
            "stream.properties" = {
              "node.latency" = latency;
              "resample.quality" = 1;
            };
          };

          # Gaming Compatibility Bridge for Pro Audio Interface
          # Creates a stereo virtual sink that routes to the Apogee Symphony Desktop
          # This solves the issue where games/Proton fail with multi-channel devices
          pipewire."90-stereo-bridge" = {
            "context.modules" = [
              {
                name = "libpipewire-module-loopback";
                args = {
                  "node.name" = "apogee_stereo_game_bridge";
                  "node.description" = "Apogee Stereo Game Bridge";

                  # Virtual stereo sink that games see
                  "capture.props" = {
                    "media.class" = "Audio/Sink";
                    "audio.position" = [
                      "FL"
                      "FR"
                    ];
                    "priority.session" = 1900;
                    "node.passive" = false;
                  };

                  # Routes to physical hardware (Pro Audio profile)
                  # Find your device with: pw-link -o | grep -i apogee
                  "playback.props" = {
                    "audio.position" = [
                      "FL"
                      "FR"
                    ];
                    "node.target" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0";
                    "node.passive" = false;
                    "stream.dont-remix" = true;
                  };
                };
              }
            ];
          };
        };

        # WirePlumber session manager
        wireplumber = {
          enable = true;
          extraConfig = {
            # Device priorities: prefer stereo bridge for games, lower priority for pro interface
            "10-device-priorities"."monitor.alsa.rules" = [
              {
                matches = [ { "node.name" = "~alsa_output.*"; } ];
                actions.update-props."priority.session" = 1000;
              }
              {
                matches = [ { "node.name" = "~alsa_output.usb-Apogee.*"; } ];
                actions.update-props."priority.session" = 100;
              }
            ];

            # Bluetooth: Enable high-quality codecs
            "10-bluez"."monitor.bluez.properties" = {
              "bluez5.enable-sbc-xq" = true;
              "bluez5.enable-msbc" = true;
              "bluez5.enable-hw-volume" = true;
              "bluez5.roles" = [
                "hsp_hs"
                "hsp_ag"
                "hfp_hf"
                "hfp_ag"
              ];
              "bluez5.codecs" = [
                "sbc"
                "sbc_xq"
                "aac"
                "ldac"
                "aptx"
                "aptx_hd"
                "aptx_ll"
                "lc3"
              ];
              "bluez5.default.rate" = 48000;
              "bluez5.default.channels" = 2;
              "bluez5.a2dp.ldac.quality" = "hq";
            };

            # Disable audio device suspension to prevent dropouts
            "51-disable-suspension"."monitor.alsa.rules" = [
              {
                matches = [
                  { "node.name" = "~alsa_input.*"; }
                  { "node.name" = "~alsa_output.*"; }
                ];
                actions.update-props."session.suspend-timeout-seconds" = 0;
              }
            ];

            # Automatic routing: games use the stereo bridge
            "90-gaming-routing" = {
              "monitor.rules" = [
                {
                  matches = [ { "node.name" = "apogee_stereo_game_bridge"; } ];
                  actions.update-props = {
                    "priority.session" = 1900;
                    "node.passive" = false;
                  };
                }
              ];

              # Route gaming applications to stereo bridge
              "monitor.stream.rules" =
                let
                  gameRouting = {
                    "node.target" = "apogee_stereo_game_bridge";
                    "node.latency" = "256/48000";
                    "session.suspend-timeout-seconds" = 0;
                  };
                in
                [
                  {
                    matches = [
                      { "application.process.binary" = "steam"; }
                      { "application.name" = "~steam_app_.*"; }
                      { "application.name" = "Steam"; }
                    ];
                    actions.update-props = gameRouting;
                  }
                  {
                    matches = [ { "application.id" = "gamescope"; } ];
                    actions.update-props = gameRouting;
                  }
                  {
                    matches = [
                      { "application.process.binary" = "~wine.*"; }
                      { "application.process.binary" = "~.*\\.exe"; }
                    ];
                    actions.update-props = gameRouting;
                  }
                ];
            };
          };
        };
      };

      # Audio utilities and environment
      environment = {
        sessionVariables = {
          PIPEWIRE_LATENCY = latency;
          SDL_AUDIODRIVER = "pulseaudio"; # For SDL2 games
          PULSE_LATENCY_MSEC = "60"; # Balance for gaming
        };

        systemPackages = [
          pkgs.pulseaudio # pactl and compatibility tools
          pkgs.alsa-utils
          pkgs.alsa-tools
        ];
      };

      # USB audio optimizations for professional interfaces
      services.udev.extraRules = ''
        # Disable autosuspend for USB audio (class 01)
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idClass}=="01", TEST=="power/control", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idClass}=="01", ATTR{power/wakeup}="disabled"

        # Apogee-specific (USB Vendor ID: 0xa07)
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0a07", ATTR{power/control}="on", ATTR{power/wakeup}="disabled"
      '';

      boot.kernelParams = lib.optionals cfg.usbAudioInterface.enable [
        "usbcore.autosuspend=-1" # Disable USB autosuspend for audio
      ];

      # CPU frequency governor for stable audio performance
      powerManagement.cpuFreqGovernor = "performance";

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

    # Noise cancellation (RNNoise) for voice chat and calls
    (mkIf cfg.noiseCancellation {
      services.pipewire.extraConfig.pipewire."99-input-denoising"."context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Noise Canceling Source";
            "media.name" = "Noise Canceling Source";
            "filter.graph".nodes = [
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

      environment.systemPackages = [ pkgs.rnnoise-plugin ];
    })

    # Echo cancellation (WebRTC) for calls and streaming
    (mkIf cfg.echoCancellation {
      services.pipewire.extraConfig.pipewire."99-echo-cancel"."context.modules" = [
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
            "aec.method" = "webrtc";
            "aec.args" = {
              "webrtc.gain_control" = true;
              "webrtc.extended_filter" = true;
              "webrtc.delay_agnostic" = true;
              "webrtc.noise_suppression" = true;
              "webrtc.high_pass_filter" = true;
            };
          };
        }
      ];
    })
  ]);
}
