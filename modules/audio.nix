# Audio - Simple PipeWire configuration
# Following NixOS wiki best practices: https://wiki.nixos.org/wiki/PipeWire
{ ... }:
{
  # NixOS audio configuration
  flake.modules.nixos.audio =
    { pkgs, ... }:
    {
      # RTKit for realtime scheduling
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;

        # Virtual stereo sink for apps that crash with multichannel/pro-audio devices
        # (e.g. Apogee Symphony Desktop). The loopback module creates a stereo sink
        # and automatically routes it to the Apogee's first two channels.
        # https://docs.pipewire.org/page_module_loopback.html
        extraConfig.pipewire."91-virtual-sink" = {
          "context.objects" = [
            {
              # Dummy driver for JACK clients / always-on nodes
              factory = "spa-node-factory";
              args = {
                "factory.name" = "support.node.driver";
                "node.name" = "Dummy-Driver";
                "priority.driver" = 8000;
              };
            }
          ];
          "context.modules" = [
            {
              name = "libpipewire-module-loopback";
              args = {
                "capture.props" = {
                  "node.name" = "Main-Output";
                  "node.description" = "Main Output";
                  "media.class" = "Audio/Sink";
                  "audio.position" = "FL,FR";
                };
                "playback.props" = {
                  "node.name" = "Main-Output-Playback";
                  "audio.position" = "AUX0,AUX1";
                  "stream.dont-remix" = true;
                  "node.target" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.multichannel-output";
                };
              };
            }
          ];
        };

        wireplumber.extraConfig = {
          # Disable device suspension to prevent audio popping/delay
          "10-disable-suspend"."monitor.alsa.rules" = [
            {
              matches = [
                { "node.name" = "~alsa_input.*"; }
                { "node.name" = "~alsa_output.*"; }
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
          };

          # Set the virtual stereo sink as the default output
          "10-default-sink"."wireplumber.settings"."default.configured.audio.sink" = {
            name = "Main-Output";
          };
        };

      };
    };

  # Darwin audio (macOS uses CoreAudio natively)
  flake.modules.darwin.audio =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.ffmpeg-full
        pkgs.flac
        pkgs.lame
      ];
    };

  # Home-manager audio tools
  flake.modules.homeManager.audio =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.pwvucontrol
        pkgs.pavucontrol
        pkgs.playerctl
        pkgs.helvum
      ];
      services.playerctld.enable = true;
    };

  flake.modules.homeManager.audioDarwin =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.lame
        pkgs.flac
      ];
    };
}
