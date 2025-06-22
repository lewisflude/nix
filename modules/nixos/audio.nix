{ pkgs, config, username, ... }: {
  environment.systemPackages = with pkgs; [
    pavucontrol
    pulsemixer
    pamixer
    playerctl
  ];
  
  security.rtkit.enable = true;
  
  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      raopOpenFirewall = true;
      wireplumber = {
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
        };
      };
    };
  };
  
  # Basic MPD setup (without hardware-specific paths)
  services.mpd = {
    enable = true;
    user = username;
    network.listenAddress = "any";
    startWhenNeeded = true;
    musicDirectory = "/home/${username}/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Output"
      }
    '';
  };
  
  systemd.services.mpd.environment = {
    XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.${username}.uid}";
  };
}