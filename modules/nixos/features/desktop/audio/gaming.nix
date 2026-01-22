# Audio routing for gaming: Apogee Symphony Desktop stereo bridge + Sunshine streaming
# Games/Proton often fail with multi-channel pro audio devices, so we create a stereo bridge
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.media.audio;

  # Gaming uses 2x quantum for stability (prevents crackling)
  quantum = if cfg.ultraLowLatency then 64 else 256;
  gamingLatency = "${toString (quantum * 2)}/48000";
in
{
  config = mkIf cfg.enable {
    services.pipewire.extraConfig.pipewire."90-stereo-bridge" = {
      "context.modules" = [
        {
          name = "libpipewire-module-loopback";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.name" = "apogee_stereo_game_bridge";
            "node.description" = "Apogee Stereo Game Bridge";
            "capture.props" = {
              "media.class" = "Audio/Sink";
              "audio.position" = [
                "FL"
                "FR"
              ];
              "priority.session" = 50;
              "node.passive" = false;
              "node.latency" = gamingLatency;
            };
            "playback.props" = {
              "audio.position" = [
                "FL"
                "FR"
              ];
              "node.target" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0";
              "node.passive" = true;
              "stream.dont-remix" = true;
              "node.latency" = gamingLatency;
              "node.autoconnect" = true;
            };
          };
        }
      ];
    };

    services.pipewire.wireplumber.extraConfig = {
      "90-gaming-routing" = {
        "monitor.alsa.rules" = [
          {
            # ALSA period-size and headroom for gaming audio devices
            # Prevents "client too slow" errors and stuttering
            matches = [
              { "node.name" = "~alsa_output.*"; }
            ];
            actions.update-props = {
              "api.alsa.period-size" = 1024; # Increased from default for stability
              "api.alsa.headroom" = 8192; # Buffer headroom for multiple streams
            };
          }
        ];

        "monitor.rules" = [
          {
            matches = [
              { "node.name" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0"; }
            ];
            actions.update-props."priority.session" = 25;
          }
          {
            matches = [ { "node.name" = "input.apogee_stereo_game_bridge"; } ];
            actions.update-props = {
              "node.passive" = false;
              "priority.session" = 100;
            };
          }
          {
            matches = [ { "node.name" = "sink-sunshine-stereo"; } ];
            actions.update-props."priority.session" = 150;
          }
        ];

        "monitor.stream.rules" =
          let
            gameRouting = {
              "node.target" = "sink-sunshine-stereo";
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

      "91-sunshine-streaming"."monitor.rules" = [
        {
          matches = [ { "node.name" = "~sink-sunshine-stereo"; } ];
          actions.update-props = {
            "audio.format" = "S16LE";
            "audio.rate" = 48000;
            "audio.channels" = 2;
            "node.latency" = "512/48000";
            "session.suspend-timeout-seconds" = 0;
          };
        }
      ];
    };
  };
}
