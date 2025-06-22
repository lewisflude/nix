{ pkgs, config, ... }: {
  environment.systemPackages = with pkgs; [
    pavucontrol
    pulsemixer
    pamixer
    playerctl
  ];
  musnix.enable = true;
  security.rtkit.enable = true;
  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      raopOpenFirewall = true;
      wireplumber = {
        configPackages = [
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
        ];
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
              args = {
                "pulse.min.req" = "32/48000";
                "pulse.default.req" = "256/48000";
                "pulse.max.req" = "8192/48000";
                "pulse.min.quantum" = "32/48000";
                "pulse.max.quantum" = "8192/48000";
                "pulse.suspend-timeout" = 5;
              };
            }
          ];
        };
        pipewire = {
          "10-airplay" = {
            "context.modules" = [
              {
                name = "libpipewire-module-raop-discover";
              }
            ];
          };
          "context.properties" = {
            "link.max-buffers" = 16;
            "log.level" = 2;
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [ 44100 48000 96000 ];
            "default.clock.quantum" = 256;
            "default.clock.min-quantum" = 32;
            "default.clock.max-quantum" = 8192;
            "core.daemon" = true;
            "core.realtime" = true;
          };
          "92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = 128;
              "default.clock.min-quantum" = 256;
              "default.clock.max-quantum" = 256;
            };
          };

          "20-playback-split.conf" = {
            "context.modules" = [
              {
                name = "libpipewire-module-loopback";
                args = {
                  "node.description" = "Speakers";
                  "capture.props" = {
                    "node.name" = "Speakers";
                    "media.class" = "Audio/Sink";
                    "audio.position" = [ "FL" "FR" ];
                  };
                  "playback.props" = {
                    "node.name" = "playback.Speakers";
                    "audio.position" = [ "AUX0" "AUX1" ];
                    "target.object" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0";
                    "stream.dont-remix" = true;
                    "node.passive" = true;
                  };
                };
              }
              {
                name = "libpipewire-module-adapter";
                args = {
                  "factory.name" = "support.null-audio-sink";
                  "node.name" = "game-audio-source";
                  "node.description" = "Game Audio Source";
                  "media.class" = "Audio/Source";
                  "audio.position" = [ "FL" "FR" ];
                };
              }
            ];
          };

          "99-alsa-compat.conf" = {
            "context.properties" = {
              "alsa.support-audio-fallback" = true;
            };
            "context.objects" = [{
              factory = "adapter";
              args = {
                "factory.name" = "support.null-audio-sink";
                "node.name" = "alsa-compatibility";
                "media.class" = "Audio/Sink";
                "audio.position" = [ "FL" "FR" ];
              };
            }];
          };
        };
      };
    };

    udev.extraRules = ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0c60", ATTRS{idProduct}=="002a", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hw:*", SUBSYSTEM=="sound", ATTRS{idVendor}=="0c60", ATTRS{idProduct}=="002a", TAG+="uaccess", GROUP="audio", MODE="0660"
    '';
  };
  systemd.services.mpd.environment = {
    XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.lewis.uid}";
  };
  services.mpd = {
    enable = true;
    user = "lewis";
    network.listenAddress = "any";
    startWhenNeeded = true;
    musicDirectory = "/home/lewis/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "My PipeWire Output"
      }
    '';
  };
}
