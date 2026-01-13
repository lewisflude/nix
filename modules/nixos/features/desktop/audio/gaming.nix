# Gaming Audio Routing Configuration
# Gaming compatibility bridge, Sunshine streaming, and game application routing
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.media.audio;

  # Gaming uses 2x quantum for stability (prevents crackling/underruns)
  # Pro audio: 64 → 128 or 256 → 512
  quantum = if cfg.ultraLowLatency then 64 else 256;
  gamingQuantum = quantum * 2;
  gamingLatency = "${toString gamingQuantum}/48000";
in
{
  config = mkIf cfg.enable {
    services.pipewire.extraConfig = {
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

    services.pipewire.wireplumber.extraConfig = {
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
}
