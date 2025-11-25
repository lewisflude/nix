{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{
  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      raopOpenFirewall = true;
      wireplumber = {
        configPackages = [
          # Set default audio devices for all applications (PulseAudio, ALSA, JACK, native PipeWire)
          # This configuration ensures consistent device selection across all audio APIs
          (pkgs.writeTextDir "share/wireplumber/main.lua.d/50-default-devices.lua" ''
            -- Increase priority of Speakers sink to make it the preferred default
            -- Higher priority = preferred by default, but users can still override
            rule = {
              matches = {
                {
                  { "node.name", "equals", "Speakers" },
                },
              },
              apply_properties = {
                ["node.description"] = "Speakers (Default)",
                ["priority.session"] = 3000,  -- Higher than hardware devices (typically 1000-2000)
                ["node.nick"] = "Speakers",    -- Friendly name for ALSA/apps
                ["media.class"] = "Audio/Sink",
              },
            }
            table.insert(alsa_monitor.rules, rule)
          '')
          # Set priorities to ensure consistent default device for Wine/Proton
          (pkgs.writeTextDir "share/wireplumber/main.lua.d/51-device-priority.lua" ''
            -- Give Apogee Symphony Desktop highest priority to ensure it's always the default
            -- This fixes intermittent Wine/Proton audio failures caused by device enumeration races
            table.insert(alsa_monitor.rules, {
              matches = {
                {
                  { "node.name", "matches", "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-*" },
                },
              },
              apply_properties = {
                ["priority.driver"] = 2000,
                ["priority.session"] = 2000,
                ["node.pause-on-idle"] = false,
              },
            })
          '')
          (pkgs.writeTextDir "share/wireplumber/main.lua.d/99-alsa-lowlatency.lua" ''
            alsa_monitor.rules = {
              {
                matches = {{{ "node.name", "matches", "alsa_output.*" }}};
                apply_properties = {
                  ["audio.format"] = "S32LE",
                  ["audio.rate"] = "96000", -- for USB soundcards it should be twice your desired rate
                  ["api.alsa.period-size"] = 2, -- defaults to 1024, tweak by trial-and-error
                  -- ["api.alsa.disable-batch"] = true, -- generally, USB soundcards use the batch mode
                },
              },
            }
          '')
          # Prevent Apogee Symphony from suspending during screen lock
          # Professional audio interfaces should maintain active state to avoid:
          # - Sample rate changes, driver reinitialization, and audio session interruptions
          (pkgs.writeTextDir "share/wireplumber/main.lua.d/99-apogee-no-suspend.lua" ''
            -- Disable suspend for Apogee Symphony interface
            rule = {
              matches = {
                {
                  { "node.name", "matches", "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-.*" },
                },
              },
              apply_properties = {
                ["session.suspend-timeout-seconds"] = 0,
              },
            }
            table.insert(alsa_monitor.rules, rule)
          '')
        ];
        # Bluetooth codec configuration
        # Note: Some configurations may affect codec availability in pavucontrol.
        # If A2DP codecs disappear, consider removing or adjusting these settings.
        # See: https://nixos.wiki/wiki/PipeWire#Bluetooth_Configuration
        extraConfig."10-bluez" = {
          "monitor.bluez.properties" = {
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;
            "bluez5.enable-hw-volume" = true;
            "bluez5.roles" = [
              "hsp_hs"
              "hsp_ag"
              "hfp_hf"
              "hfp_ag"
            ];
          };
        };
      };
      extraConfig = {
        pipewire-pulse = {
          "context.properties" = {
            "log.level" = 2;
          };
          "context.modules" = [
            {
              name = "libpipewire-module-protocol-pulse";
              args = { };
            }
          ];
          # PulseAudio backend configuration for low-latency operation
          # Values should not be lower than main pipewire quantum settings
          "pulse.properties" = {
            "pulse.min.req" = "128/48000";
            "pulse.default.req" = "256/48000";
            "pulse.max.req" = "8192/48000";
            "pulse.min.quantum" = "128/48000";
            "pulse.max.quantum" = "8192/48000";
          };
          "stream.properties" = {
            "node.latency" = "128/48000";
            "resample.quality" = 4; # 4 = balanced quality/performance
          };
        };
        pipewire = {
          "99-silent-bell.conf" = {
            "context.properties" = {
              "module.x11.bell" = false;
            };
          };
          "10-airplay" = {
            "context.modules" = [
              {
                name = "libpipewire-module-raop-discover";
                args = {
                  "raop.latency.ms" = 500;
                };
              }
            ];
          };
          # Core PipeWire configuration optimized for professional audio
          # Balanced between low-latency and stability for Apogee Symphony Desktop
          "context.properties" = {
            "link.max-buffers" = 16;
            "log.level" = 2;
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [
              44100
              48000
              96000
            ];
            # Buffer settings: quantum=128 provides ~2.7ms latency at 48kHz
            # This is a good balance for pro audio work without risking underruns
            # Increase quantum if you experience audio dropouts/crackles
            "default.clock.quantum" = 128;
            "default.clock.min-quantum" = 32; # Allow apps to request lower latency
            "default.clock.max-quantum" = 8192; # Allow apps to request higher stability
            "core.daemon" = true;
            "core.realtime" = true;
          };
          "99-alsa-compat.conf" = {
            "context.properties" = {
              "alsa.support-audio-fallback" = true;
            };
            "context.objects" = [
              {
                factory = "adapter";
                args = {
                  "factory.name" = "support.null-audio-sink";
                  "node.name" = "alsa-compatibility";
                  "media.class" = "Audio/Sink";
                  "audio.position" = [
                    "FL"
                    "FR"
                  ];
                };
              }
            ];
          };
        };
      };
    };
  };
}
