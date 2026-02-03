# Audio Feature Module - Dendritic Pattern
# Single file containing both NixOS system config and home-manager user config
# Usage: Import flake.modules.nixos.audio in host definition
{ config, ... }:
let
  constants = config.constants;
  audioConstants = constants.audio;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.audio =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib) mkDefault optional;

      # Default latency settings (can be overridden by hosts)
      quantum = 256;
      latency = "${toString quantum}/48000";
      gamingLatency = "${toString (quantum * 2)}/48000";
    in
    {
      # ========================================================================
      # Core PipeWire Configuration
      # ========================================================================
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

          # Create stereo null sinks and loopback routing for Apogee
          # This solves quickshell crashes caused by Qt FFmpeg plugin not supporting 10-channel layouts
          # Applications output to stereo sinks, which are automatically routed to Apogee hardware
          pipewire."91-null-sinks" = {
            "context.objects" = [
              {
                # Dummy driver for JACK clients
                factory = "spa-node-factory";
                args = {
                  "factory.name" = "support.node.driver";
                  "node.name" = "Dummy-Driver";
                  "priority.driver" = 8000;
                };
              }
              {
                # Stereo output bridge for games/applications
                factory = "adapter";
                args = {
                  "factory.name" = "support.null-audio-sink";
                  "node.name" = "apogee_stereo_game_bridge";
                  "node.description" = "Apogee Stereo Bridge";
                  "media.class" = "Audio/Sink";
                  "audio.position" = "FL,FR";
                  "audio.channels" = 2;
                };
              }
              {
                # Default stereo output for system sounds
                factory = "adapter";
                args = {
                  "factory.name" = "support.null-audio-sink";
                  "node.name" = "apogee_stereo_default";
                  "node.description" = "Apogee Stereo Default";
                  "media.class" = "Audio/Sink";
                  "audio.position" = "FL,FR";
                  "audio.channels" = 2;
                };
              }
            ];
          };

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

            # Apogee Symphony Desktop - Use pro-audio profile for full channel access
            "10-apogee-stereo"."monitor.alsa.rules" = [
              {
                matches = [
                  { "device.name" = "~alsa_card.usb-Apogee_Electronics_Corp_Symphony_Desktop-00"; }
                ];
                actions.update-props = {
                  "api.alsa.use-acp" = true;
                  "device.disabled" = false;
                };
              }
              {
                matches = [
                  { "node.name" = "~alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output.*"; }
                ];
                actions.update-props = {
                  "api.alsa.period-size" = 256;
                  "session.suspend-timeout-seconds" = 0;
                  "priority.session" = audioConstants.priorities.fallback;
                };
              }
            ];

            # Device priorities
            "10-device-priorities"."monitor.alsa.rules" = [
              # Medium priority for ALSA outputs (onboard audio, etc.)
              {
                matches = [ { "node.name" = "~alsa_output.*"; } ];
                actions.update-props."priority.session" = audioConstants.priorities.onboard;
              }
              # USB audio interfaces get medium-low priority (we prefer virtual sinks)
              {
                matches = [ { "node.name" = audioConstants.devices.usbAudioClass; } ];
                actions.update-props."priority.session" = audioConstants.priorities.fallback + 5;
              }
            ];

            "10-bridge-priority"."monitor.rules" = [
              {
                # Default stereo sink - highest priority for system sounds
                matches = [ { "node.name" = "apogee_stereo_default"; } ];
                actions.update-props = {
                  "priority.session" = audioConstants.priorities.primaryInterface;
                  "node.passive" = false;
                };
              }
              {
                # Gaming bridge - medium-high priority
                matches = [ { "node.name" = "apogee_stereo_game_bridge"; } ];
                actions.update-props = {
                  "priority.session" = 90;
                  "node.passive" = false;
                };
              }
            ];

            # Auto-link loopbacks to Apogee hardware
            "10-apogee-loopback-links"."monitor.rules" = [
              {
                # Link game loopback output to Apogee hardware
                matches = [ { "node.name" = "output.apogee_game_loopback"; } ];
                actions.update-props = {
                  "node.autoconnect" = true;
                  "node.target" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0";
                };
              }
              {
                # Link game loopback input to game bridge monitor
                matches = [ { "node.name" = "input.apogee_game_loopback"; } ];
                actions.update-props = {
                  "node.autoconnect" = true;
                  "node.target" = "apogee_stereo_game_bridge";
                };
              }
              {
                # Link default loopback output to Apogee hardware
                matches = [ { "node.name" = "output.apogee_default_loopback"; } ];
                actions.update-props = {
                  "node.autoconnect" = true;
                  "node.target" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0";
                };
              }
              {
                # Link default loopback input to default bridge monitor
                matches = [ { "node.name" = "input.apogee_default_loopback"; } ];
                actions.update-props = {
                  "node.autoconnect" = true;
                  "node.target" = "apogee_stereo_default";
                };
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

              "monitor.rules" = [
                # Lower priority for USB audio when gaming bridge is active
                {
                  matches = [ { "node.name" = audioConstants.devices.usbAudioClass; } ];
                  actions.update-props."priority.session" = audioConstants.priorities.fallback + 15;
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
                  # Default stereo routing for everything else
                  defaultRouting = {
                    "node.target" = "apogee_stereo_default";
                    "node.latency" = latency;
                    "resample.quality" = 10;
                    "session.suspend-timeout-seconds" = 0;
                  };
                in
                [
                  # Route games to gaming bridge or Sunshine
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
                  # Route everything else to default stereo sink
                  {
                    matches = [ { "media.class" = "Stream/Output/Audio"; } ];
                    actions.update-props = defaultRouting;
                  }
                ];
            };
          };
        };
      };

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

      # Script to link stereo bridges directly to Apogee hardware
      systemd.user.services.apogee-audio-links = {
        description = "Link Apogee Stereo Bridges to Hardware";
        after = [ "wireplumber.service" ];
        wantedBy = [ "pipewire.service" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.writeShellScript "apogee-link" ''
            sleep 3  # Wait for WirePlumber

            # Link game bridge directly to Apogee (channels 0-1)
            ${pkgs.pipewire}/bin/pw-link apogee_stereo_game_bridge:monitor_FL alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX0 || true
            ${pkgs.pipewire}/bin/pw-link apogee_stereo_game_bridge:monitor_FR alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX1 || true

            # Link default bridge to Apogee (channels 2-3)
            ${pkgs.pipewire}/bin/pw-link apogee_stereo_default:monitor_FL alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX2 || true
            ${pkgs.pipewire}/bin/pw-link apogee_stereo_default:monitor_FR alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX3 || true
          ''}";
        };
      };
    };

  # ==========================================================================
  # Noise Cancellation NixOS Module (optional)
  # ==========================================================================
  flake.modules.nixos.noiseCancellation =
    { pkgs, ... }:
    {
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
    };

  # ==========================================================================
  # Echo Cancellation NixOS Module (optional)
  # ==========================================================================
  flake.modules.nixos.echoCancellation =
    { ... }:
    {
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
    };

  # ==========================================================================
  # Darwin System Configuration
  # ==========================================================================
  flake.modules.darwin.audio =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) optionals;
    in
    {
      # macOS handles audio natively via CoreAudio
      # We only provide CLI tools and audio production packages
      environment.systemPackages = [
        # Basic audio packages
        pkgs.ffmpeg-full
        pkgs.flac
        pkgs.lame
        pkgs.opusTools
        pkgs.vorbis-tools

        # Apogee reconnect helper
        (pkgs.writeShellScriptBin "apogee-reconnect" ''
          echo "Resetting CoreAudio..."
          sudo killall coreaudiod
          sleep 1
          echo "Done! Apogee should be available now."
        '')
      ];
    };

  # ==========================================================================
  # Home-Manager User Configuration (NixOS)
  # ==========================================================================
  flake.modules.homeManager.audio =
    { pkgs, lib, ... }:
    {
      # PipeWire control and utilities
      home.packages = [
        pkgs.pwvucontrol # Modern PipeWire volume control (GTK4)
        pkgs.helvum # PipeWire patchbay for audio routing

        # PulseAudio compatibility tools
        pkgs.pavucontrol # PulseAudio volume control (works with PipeWire)
        pkgs.paprefs # PulseAudio preferences

        # Media control
        pkgs.playerctl # MPRIS media player controller

        # Audio effects and processing
        pkgs.easyeffects # Audio effects for PipeWire

        # Pro audio tools and diagnostics
        pkgs.jack2 # JACK Audio Connection Kit (for jack_delay latency testing)
      ];

      # Playerctl configuration for media key bindings
      services.playerctld.enable = true;
    };

  # ==========================================================================
  # Home-Manager User Configuration (Darwin)
  # ==========================================================================
  flake.modules.homeManager.audioDarwin =
    { pkgs, ... }:
    {
      # macOS-specific audio utilities
      home.packages = [
        pkgs.lame # MP3 encoding
        pkgs.flac # FLAC codec
      ];
    };
}
