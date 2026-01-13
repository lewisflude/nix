# WirePlumber Session Manager Configuration
# Device priorities, ALSA sequencer disabling, and suspension prevention
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.media.audio;
in
{
  config = mkIf cfg.enable {
    services.pipewire.wireplumber = {
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
      };
    };
  };
}
