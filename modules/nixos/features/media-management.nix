# Bridge module: Maps host.features.mediaManagement to host.services.mediaManagement
# This allows host configurations to use the features interface
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.host.features.mediaManagement or {};
in {
  config = mkIf (cfg.enable or false) {
    # Map features to services
    host.services.mediaManagement = {
      enable = true;
      dataPath = cfg.dataPath or "/mnt/storage";
      timezone = cfg.timezone or "Europe/London";
      prowlarr = cfg.prowlarr or {};
      radarr = cfg.radarr or {};
      sonarr = cfg.sonarr or {};
      lidarr = cfg.lidarr or {};
      readarr = cfg.readarr or {};
      sabnzbd = cfg.sabnzbd or {};
      qbittorrent = cfg.qbittorrent or {};
      jellyfin = cfg.jellyfin or {};
      jellyseerr = cfg.jellyseerr or {};
      flaresolverr = cfg.flaresolverr or {};
      unpackerr = cfg.unpackerr or {};
      navidrome = cfg.navidrome or {};
    };
  };
}
