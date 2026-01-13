{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.host.features.mediaManagement;
in
{
  config = mkMerge [
    (mkIf cfg.enable {

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
        inherit (cfg) jellyfin;
        inherit (cfg) jellyseerr;
        inherit (cfg) flaresolverr;
        inherit (cfg) unpackerr;
        inherit (cfg) navidrome;
      };
    })

    {
      assertions = [
        {
          assertion = cfg.prowlarr.enable -> cfg.enable;
          message = "Prowlarr requires mediaManagement feature to be enabled";
        }
        {
          assertion = cfg.radarr.enable -> cfg.enable;
          message = "Radarr requires mediaManagement feature to be enabled";
        }
        {
          assertion = cfg.sonarr.enable -> cfg.enable;
          message = "Sonarr requires mediaManagement feature to be enabled";
        }
        {
          assertion = cfg.lidarr.enable -> cfg.enable;
          message = "Lidarr requires mediaManagement feature to be enabled";
        }
        {
          assertion = cfg.readarr.enable -> cfg.enable;
          message = "Readarr requires mediaManagement feature to be enabled";
        }
        {
          assertion = cfg.listenarr.enable -> cfg.enable;
          message = "Listenarr requires mediaManagement feature to be enabled";
        }
        {
          assertion = cfg.sabnzbd.enable -> cfg.enable;
          message = "SABnzbd requires mediaManagement feature to be enabled";
        }
        {
          assertion = cfg.jellyfin.enable -> cfg.enable;
          message = "Jellyfin requires mediaManagement feature to be enabled";
        }
        {
          assertion = cfg.jellyseerr.enable -> cfg.enable;
          message = "Jellyseerr requires mediaManagement feature to be enabled";
        }
        {
          assertion = cfg.flaresolverr.enable -> cfg.enable;
          message = "FlareSolverr requires mediaManagement feature to be enabled";
        }
        {
          assertion = cfg.unpackerr.enable -> cfg.enable;
          message = "Unpackerr requires mediaManagement feature to be enabled";
        }
        {
          assertion = cfg.navidrome.enable -> cfg.enable;
          message = "Navidrome requires mediaManagement feature to be enabled";
        }
      ];
    }
  ];
}
