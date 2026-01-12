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

  # Gaming uses 2x quantum for stability (prevents crackling/underruns)
  # Pro audio: 64 → 128 or 256 → 512
  gamingQuantum = quantum * 2;
  gamingLatency = "${toString gamingQuantum}/48000";
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
              # Disable ALSA sequencer to prevent crashes with phantom MIDI devices
              # See: https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/3644
              "alsa.seq.disabled" = true;
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
              "resample.quality" = 4; # Medium quality (was 1) - prevents crackling
            };
          };

          # Gaming Compatibility Bridge for Pro Audio Interface
          # Creates a stereo virtual sink that routes to the Apogee Symphony Desktop
          # This solves the issue where games/Proton fail with multi-channel devices
          pipewire."90-stereo-bridge" = {
            "context.modules" = [
              {
                name = "libpipewire-module-loopback";
                # Add flags to prevent crashes if Apogee is not connected
                flags = [
                  "ifexists"
                  "nofail"
                ];
                args = {
                  "node.name" = "apogee_stereo_game_bridge";
                  "node.description" = "Apogee Stereo Game Bridge";

                  # Virtual stereo sink that games see
                  # Priority set low (50) so regular apps prefer Apogee direct (100)
                  # Games are forced to this bridge via stream rules anyway, so priority doesn't matter for them
                  "capture.props" = {
                    "media.class" = "Audio/Sink";
                    "audio.position" = [
                      "FL"
                      "FR"
                    ];
                    "priority.session" = 50; # Lower than Apogee direct (100) - games forced via rules
                    "node.passive" = false;
                    "node.latency" = gamingLatency;
                  };

                  # Routes to physical hardware (Pro Audio profile)
                  # Find your device with: pw-link -o | grep -i apogee
                  "playback.props" = {
                    "audio.position" = [
                      "FL"
                      "FR"
                    ];
                    "node.target" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0";
                    "node.passive" = true; # Changed to true - prevents hanging if device not found
                    "stream.dont-remix" = true;
                    "node.latency" = gamingLatency;
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
            # Disable ALSA sequencer monitoring to prevent crashes
            # Matches the alsa.seq.disabled setting in PipeWire config
            "10-disable-alsa-seq"."monitor.alsa.rules" = [
              {
                matches = [ { "device.name" = "~alsa_card.*"; } ];
                actions.update-props = {
                  "api.alsa.disable-midi" = true;
                  "api.alsa.disable-seq" = true;
                };
              }
            ];

            # Device priorities: Apogee direct for regular apps, lower priority for bridge (games forced via rules)
            "10-device-priorities"."monitor.alsa.rules" = [
              {
                # Apogee direct - preferred for regular apps (highest priority for physical outputs)
                matches = [ { "node.name" = "~alsa_output.usb-Apogee.*"; } ];
                actions.update-props."priority.session" = 100;
              }
              {
                # Generic ALSA outputs - lower priority than Apogee (fallback only)
                # Note: HDMI devices are disabled separately, so this mainly affects future devices
                matches = [ { "node.name" = "~alsa_output.*"; } ];
                actions.update-props."priority.session" = 50;
              }
            ];

            # Explicitly set bridge priority in WirePlumber (matches module definition)
            # Bridge has priority 50 - lower than Apogee (100) so regular apps don't use it
            # Games are forced to bridge via stream rules anyway
            "10-bridge-priority"."monitor.rules" = [
              {
                matches = [
                  { "node.name" = "~input.apogee_stereo_game_bridge"; }
                  { "node.name" = "~output.apogee_stereo_game_bridge"; }
                ];
                actions.update-props = {
                  "priority.session" = 50; # Lower than Apogee direct (100)
                };
              }
            ];

            # Configure HDMI audio devices
            # NVIDIA HDMI is enabled for Sunshine streaming with optimized settings
            # Intel PCH is set to very low priority as a backup (but not disabled)
            "10-hdmi-audio-config" = {
              # Device-level rules (for cards)
              "monitor.alsa.rules" = [
                {
                  # Enable NVIDIA HDMI audio device
                  matches = [
                    { "device.name" = "~alsa_card.pci-0000_01_00.1"; } # NVIDIA AD102 High Definition Audio Controller
                  ];
                  actions.update-props = {
                    "device.disabled" = false; # Explicitly enable (was disabled before)
                    "priority.session" = 30; # Lower than Apogee (100) but higher than Intel (10)
                  };
                }
                {
                  # Set Intel PCH to low priority (kept as backup fallback)
                  matches = [
                    { "device.name" = "~alsa_card.pci-0000_00_1f.3"; } # Intel PCH Built-in Audio
                  ];
                  actions.update-props = {
                    "priority.session" = 10;
                  };
                }
              ];

              # Node-level rules (for actual audio streams)
              "monitor.rules" = [
                {
                  # Configure NVIDIA HDMI output node for low-latency streaming
                  matches = [
                    { "node.name" = "~alsa_output.pci-0000_01_00.1.*"; }
                  ];
                  actions.update-props = {
                    "audio.format" = "S16LE"; # Force 16-bit (hardware native format)
                    "audio.rate" = 48000;
                    "audio.channels" = 2;
                    "audio.position" = "FL,FR";
                    "api.alsa.period-size" = 256; # Reduce from 1024 for lower latency
                    "api.alsa.period-num" = 2; # Reduce from 32 for lower latency
                    "api.alsa.headroom" = 0;
                    "session.suspend-timeout-seconds" = 0; # Never suspend during streaming
                  };
                }
              ];
            };

            # Bluetooth: Enable high-quality codecs
            # Bluetooth devices get priority 200 when connected (higher than Apogee for auto-selection)
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

            # Set Bluetooth device priority (higher than Apogee when connected)
            # Bluetooth sinks get higher priority so they auto-select when connected
            "10-bluetooth-priority"."monitor.rules" = [
              {
                matches = [ { "node.name" = "~bluez_output.*"; } ];
                actions.update-props = {
                  "priority.session" = 200; # Higher than Apogee (100) - auto-select when connected
                };
              }
            ];

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

            # Automatic routing: games use Sunshine virtual sink for streaming
            # When not streaming, games will use default sink (Apogee or bridge)
            "90-gaming-routing" = {
              "monitor.rules" = [
                {
                  matches = [ { "node.name" = "input.apogee_stereo_game_bridge"; } ];
                  actions.update-props = {
                    "node.passive" = false;
                    # Lower priority - only used when Sunshine sink not available
                    "priority.session" = 50;
                  };
                }
                {
                  # Give Sunshine virtual sink higher priority for games
                  matches = [
                    { "node.name" = "sink-sunshine-stereo"; }
                  ];
                  actions.update-props = {
                    "priority.session" = 150; # Higher than Apogee bridge (50)
                  };
                }
              ];

              # Route gaming applications to Sunshine virtual sink (highest priority)
              # Falls back to Apogee bridge if Sunshine sink doesn't exist
              "monitor.stream.rules" =
                let
                  gameRouting = {
                    "node.target" = "sink-sunshine-stereo";
                    "node.latency" = gamingLatency;
                    "resample.quality" = 4; # Medium quality to prevent crackling
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

            # Sunshine streaming optimization
            # Configure Sunshine's virtual sink for low-latency streaming
            "91-sunshine-streaming" = {
              "monitor.rules" = [
                {
                  # Optimize Sunshine virtual sink properties
                  matches = [
                    { "node.name" = "~sink-sunshine-stereo"; }
                    { "node.name" = "~sink-sunshine-stereo.monitor"; }
                  ];
                  actions.update-props = {
                    "audio.format" = "S16LE"; # 16-bit format for streaming
                    "audio.rate" = 48000;
                    "audio.channels" = 2;
                    "audio.position" = "FL,FR";
                    "node.latency" = "512/48000"; # Gaming latency for stability (prevents crackling/underruns)
                    "session.suspend-timeout-seconds" = 0; # Never suspend during streaming
                    "resample.quality" = 4; # Medium quality resampling (balance speed/quality)
                  };
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

      # Blacklist ALSA sequencer kernel modules to prevent PipeWire crashes
      # These modules cause snd_seq_event_input crashes in PipeWire < 1.4.10
      # Since we're disabling alsa.seq in PipeWire config, we don't need these
      boot.blacklistedKernelModules = [
        "snd_seq"
        "snd_seq_dummy"
        "snd_seq_midi"
        "snd_seq_midi_event"
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
