{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.mediaManagement;
in
{
  config = mkIf cfg.enable {

    host.services.mediaManagement = {
      enable = true;
      inherit (cfg) dataPath;
      inherit (cfg) timezone;
      inherit (cfg) prowlarr;
      inherit (cfg) radarr;
      inherit (cfg) sonarr;
      inherit (cfg) lidarr;
      inherit (cfg) readarr;
      inherit (cfg) listenarr;
      inherit (cfg) sabnzbd;
      inherit (cfg) qbittorrent;
      inherit (cfg) transmission;
      inherit (cfg) jellyfin;
      inherit (cfg) jellyseerr;
      inherit (cfg) flaresolverr;
      inherit (cfg) unpackerr;
      inherit (cfg) navidrome;
    };
  };
}
