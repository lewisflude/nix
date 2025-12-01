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
      dataPath = cfg.dataPath or "/mnt/storage";
      timezone = cfg.timezone or "Europe/London";
      prowlarr = cfg.prowlarr or { };
      radarr = cfg.radarr or { };
      sonarr = cfg.sonarr or { };
      lidarr = cfg.lidarr or { };
      readarr = cfg.readarr or { };
      listenarr = cfg.listenarr or { };
      sabnzbd = cfg.sabnzbd or { };
      qbittorrent = cfg.qbittorrent or { };
      transmission = cfg.transmission or { };
      jellyfin = cfg.jellyfin or { };
      jellyseerr = cfg.jellyseerr or { };
      flaresolverr = cfg.flaresolverr or { };
      unpackerr = cfg.unpackerr or { };
      navidrome = cfg.navidrome or { };
    };
  };
}
