# Bridge module: Forwards host.features.mediaManagement to host.services.mediaManagement
# TODO: Consolidate feature and service options to eliminate this indirection
# See docs/reference/REFACTORING_EXAMPLES.md for the recommended pattern
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
      inherit (cfg)
        dataPath
        timezone
        prowlarr
        radarr
        sonarr
        lidarr
        readarr
        listenarr
        sabnzbd
        qbittorrent
        transmission
        jellyfin
        jellyseerr
        flaresolverr
        unpackerr
        navidrome
        ;
    };
  };
}
