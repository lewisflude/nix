# Navidrome - Music server and streamer compatible with Subsonic/Airsonic
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.navidrome.enable =
    mkEnableOption "Navidrome music server"
    // {
      default = true;
    };

  config = mkIf (cfg.enable && cfg.navidrome.enable) {
    services.navidrome = {
      enable = true;
      openFirewall = true;
      inherit (cfg) user;
      inherit (cfg) group;
      settings = {
        Port = 4533;
        Address = "0.0.0.0";
        MusicFolder = "${cfg.dataPath}/media/music";
        DataFolder = "/var/lib/navidrome";
        EnableInsightsCollector = false;
      };
    };

    # Set timezone
    systemd.services.navidrome = {
      environment = {
        TZ = cfg.timezone;
      };
    };

    # Grant access to audio for transcoding
    users.users.${cfg.user}.extraGroups = [
      "audio"
    ];
  };
}
