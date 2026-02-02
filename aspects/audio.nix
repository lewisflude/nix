# Audio Aspect
#
# Combines all audio-related configuration in a single file.
# Reads options from config.host.features.media.audio (defined in modules/shared/host-options/features/media.nix)
#
# Platform support:
# - NixOS: PipeWire with low-latency config, WirePlumber, noise/echo cancellation
# - Darwin: CoreAudio tools, audio production packages, Apogee reconnect helper
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
    optional
    ;
  inherit (lib.lists) optionals;
  cfg = config.host.features.media.audio;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;

  audioConstants = (import ../lib/constants.nix).audio;

  quantum = if cfg.ultraLowLatency then 64 else 256;
  latency = "${toString quantum}/48000";
  gamingLatency = "${toString (quantum * 2)}/48000";
in
{
  config = mkMerge [
    # ================================================================
    # Assertions (both platforms)
    # ================================================================
    {
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

    # ================================================================
    # NixOS - Core PipeWire Configuration
    # ================================================================
    (mkIf (cfg.enable && isLinux) {
      security.rtkit.enable = true;

      security.pam.loginLimits = [
        {
          domain = "@audio";
          type = "-";
          item = "memlock";
          value = "unlimited";
        }
        {
          domain = "@audio";
          type = "-";
          item = "rtprio";
          value = "99";
        }
        {
          domain = "@audio";
          type = "-";
          item = "nice";
          value = "-11";
        }
      ];

      services.pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
        jack.enable = true;

        extraConfig = {
          client."92-high-quality-resample"."stream.properties"."resample.quality" = 10;

          pipewire."92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = quantum;
              "default.clock.min-quantum" = 64;
              "default.clock.max-quantum" = 2048;
              "default.clock.allowed-rates" = [
                44100
                48000
                88200
                96000
                176400
                192000
              ];
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
              "resample.quality" = 10;
            };
            "pulse.rules" = [
              {
                matches = [
                  { "application.process.binary" = "Discord"; }
                  { "application.process.binary" = "discord"; }
                ];
                actions.update-props."pulse.min.quantum" = "1024/48000";
              }
            ];
          };
        };

        wireplumber = {
          enable = true;
          extraConfig = {
            # Disable ALSA sequencer
            "10-disable-alsa-seq"."monitor.alsa.rules" = [
              {
                matches = [ { "device.name" = "~alsa_card.*"; } ];
                actions.update-props = {
                  "api.alsa.disable-midi" = true;
                  "api.alsa.disable-seq" = true;
                };
              }
            ];

            # Device priorities
            "10-device-priorities"."monitor.alsa.rules" = [
              # Medium priority for ALSA outputs (onboard audio, etc.) - GENERAL RULE FIRST
              {
                matches = [ { "node.name" = "~alsa_output.*"; } ];
                actions.update-props."priority.session" = audioConstants.priorities.onboard;
              }
              # High priority for USB audio interfaces - SPECIFIC RULE SECOND (OVERRIDES)
              {
                matches = [ { "node.name" = audioConstants.devices.usbAudioClass; } ];
                actions.update-props."priority.session" = audioConstants.priorities.primaryInterface;
              }
            ];

            "10-bridge-priority"."monitor.rules" = [
              {
                matches = [
                  { "node.name" = "~input.apogee_stereo_game_bridge"; }
                  { "node.name" = "~output.apogee_stereo_game_bridge"; }
                ];
                actions.update-props."priority.session" = 50;
              }
            ];

            # Disable suspension
            "51-disable-suspension"."monitor.alsa.rules" = [
              {
                matches = [
                  { "node.name" = "~alsa_input.*"; }
                  { "node.name" = "~alsa_output.*"; }
                ];
                actions.update-props."session.suspend-timeout-seconds" = 0;
              }
            ];

            "51-disable-bluetooth-suspension"."monitor.bluez.rules" = [
              {
                matches = [
                  { "node.name" = "~bluez_input.*"; }
                  { "node.name" = "~bluez_output.*"; }
                ];
                actions.update-props."session.suspend-timeout-seconds" = 0;
              }
            ];

            # Bluetooth codecs
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
                "aptx_ll_duplex"
                "lc3"
                "lc3plus_hr"
              ];
              "bluez5.default.rate" = 48000;
              "bluez5.default.channels" = 2;
              "bluez5.a2dp.ldac.quality" = "hq";
            };

            "10-bluetooth-priority"."monitor.rules" = [
              {
                matches = [ { "node.name" = "~bluez_output.*"; } ];
                actions.update-props."priority.session" = 80;
              }
            ];

            # HDMI audio
            "10-hdmi-audio-config" = {
              "monitor.alsa.rules" = [
                {
                  matches = [ { "device.name" = "~alsa_card.pci-0000_01_00.1"; } ];
                  actions.update-props = {
                    "device.disabled" = false;
                    "priority.session" = 30;
                  };
                }
                {
                  matches = [ { "device.name" = "~alsa_card.pci-0000_00_1f.3"; } ];
                  actions.update-props."priority.session" = 10;
                }
              ];

              "monitor.rules" = [
                {
                  matches = [ { "node.name" = "~alsa_output.pci-0000_01_00.1.*"; } ];
                  actions.update-props = {
                    "audio.format" = "S16LE";
                    "audio.rate" = 48000;
                    "audio.channels" = 2;
                    "audio.position" = "FL,FR";
                    "api.alsa.period-size" = 256;
                    "api.alsa.period-num" = 2;
                    "api.alsa.headroom" = 0;
                    "session.suspend-timeout-seconds" = 0;
                  };
                }
              ];
            };

            # Gaming routing
            "90-gaming-routing" = {
              "monitor.alsa.rules" = [
                {
                  matches = [ { "node.name" = "~alsa_output.*"; } ];
                  actions.update-props = {
                    "api.alsa.period-size" = 1024;
                    "api.alsa.headroom" = 8192;
                  };
                }
              ];

              "monitor.rules" =
                [
                  # Lower priority for USB audio when gaming bridge is active
                  {
                    matches = [ { "node.name" = audioConstants.devices.usbAudioClass; } ];
                    actions.update-props."priority.session" = audioConstants.priorities.fallback + 15; # 25
                  }
                  # Gaming bridge - high priority for game audio
                  {
                    matches = [
                      { "node.name" = "input.${audioConstants.virtualSinks.gamingBridge}"; }
                    ];
                    actions.update-props = {
                      "node.passive" = false;
                      "priority.session" = audioConstants.priorities.gamingBridge;
                    };
                  }
                ]
                ++ optional (config.services.sunshine.enable or false) {
                  # Sunshine virtual sink - only when Sunshine is enabled
                  matches = [ { "node.name" = audioConstants.virtualSinks.sunshineStereo; } ];
                  actions.update-props."priority.session" = audioConstants.priorities.sunshine;
                };

              "monitor.stream.rules" =
                let
                  # Route games to Sunshine when streaming, gaming bridge otherwise
                  gameRoutingTarget =
                    if (config.services.sunshine.enable or false) then
                      audioConstants.virtualSinks.sunshineStereo
                    else
                      audioConstants.virtualSinks.gamingBridge;
                  gameRouting = {
                    "node.target" = gameRoutingTarget;
                    "node.latency" = gamingLatency;
                    "resample.quality" = 4;
                    "session.suspend-timeout-seconds" = 0;
                  };
                in
                [
                  {
                    matches = [
                      { "application.process.binary" = "steam"; }
                      { "application.name" = "~steam_app_.*"; }
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

      # Note: PulseAudio compatibility provided by PipeWire (services.pipewire.pulse.enable)
      # User tools (pavucontrol, paprefs) installed via home-manager in home/nixos/hardware-tools/audio.nix

      # USB autosuspend prevention
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="01", TEST=="power/control", \
          ATTR{power/control}="on", ATTR{power/wakeup}="disabled", ATTR{power/autosuspend}="-1"
      '';

      # Blacklist ALSA sequencer modules
      boot.blacklistedKernelModules = [
        "snd_seq"
        "snd_seq_dummy"
        "snd_seq_midi"
        "snd_seq_midi_event"
      ];
    })

    # ================================================================
    # NixOS - Noise Cancellation
    # ================================================================
    (mkIf (cfg.enable && cfg.noiseCancellation && isLinux) {
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

    # ================================================================
    # NixOS - Sunshine Streaming Configuration
    # ================================================================
    (mkIf (cfg.enable && (config.services.sunshine.enable or false) && isLinux) {
      services.pipewire.wireplumber.extraConfig."91-sunshine-streaming"."monitor.rules" = [
        {
          matches = [ { "node.name" = "~${audioConstants.virtualSinks.sunshineStereo}"; } ];
          actions.update-props = {
            "audio.format" = "S16LE";
            "audio.rate" = 48000;
            "audio.channels" = 2;
            "node.latency" = "512/48000";
            "session.suspend-timeout-seconds" = 0;
          };
        }
      ];
    })

    # ================================================================
    # NixOS - Echo Cancellation
    # ================================================================
    (mkIf (cfg.enable && cfg.echoCancellation && isLinux) {
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

    # ================================================================
    # Darwin Configuration
    # ================================================================
    (mkIf (cfg.enable && isDarwin) {
      # macOS handles audio natively via CoreAudio
      # We only provide CLI tools and audio production packages

      environment.systemPackages =
        [
          # Basic audio packages
          pkgs.ffmpeg-full # Comprehensive audio/video conversion
          pkgs.flac
          pkgs.lame
          pkgs.opusTools
          pkgs.vorbis-tools
        ]
        ++ optionals cfg.production [
          # Audio production tools
          pkgs.portaudio
          pkgs.rtaudio
          pkgs.rtmidi
          pkgs.jack2
          # Note: qjackctl is Linux-only, not available on macOS
        ];

      # Audio production utilities that benefit from system-wide installation
      # DAWs and heavy audio software are typically installed via App Store or DMG
    })

    # ================================================================
    # Darwin - Apogee Reconnect Helper
    # ================================================================
    (mkIf (cfg.enable && isDarwin) {
      # Simple script to reset CoreAudio after KVM switch
      # Just run: apogee-reconnect
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "apogee-reconnect" ''
          echo "Resetting CoreAudio..."
          sudo killall coreaudiod
          sleep 1
          echo "Done! Apogee should be available now."
        '')
      ];
    })
  ];
}
