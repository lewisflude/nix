{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.host.features.mediaManagement = {
    enable = mkEnableOption "native media management services" // {
      default = false;
    };

    dataPath = mkOption {
      type = types.str;
      default = "/mnt/storage";
      description = "Path to media storage directory";
      example = "/mnt/storage";
    };

    timezone = mkOption {
      type = types.str;
      default = "Europe/London";
      description = "Timezone for media services";
      example = "America/New_York";
    };

    prowlarr.enable = mkEnableOption "Prowlarr indexer manager" // { default = true; };
    radarr.enable = mkEnableOption "Radarr movie management" // { default = true; };
    sonarr.enable = mkEnableOption "Sonarr TV show management" // { default = true; };
    lidarr.enable = mkEnableOption "Lidarr music management" // { default = true; };
    readarr.enable = mkEnableOption "Readarr book management" // { default = true; };

    listenarr = {
      enable = mkEnableOption "Listenarr audiobook management";
      publicUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Public URL for Listenarr (used by Discord bot)";
      };
    };

    sabnzbd.enable = mkEnableOption "SABnzbd usenet downloader" // { default = true; };

    qbittorrent = mkOption {
      type = types.attrs;
      default = { };
      description = "qBittorrent configuration (options defined in service module)";
    };

    transmission = mkOption {
      type = types.attrs;
      default = { };
      description = "Transmission configuration (options defined in service module)";
    };

    jellyfin.enable = mkEnableOption "Jellyfin media server" // { default = true; };
    jellyseerr.enable = mkEnableOption "Jellyseerr request management" // { default = true; };
    flaresolverr.enable = mkEnableOption "FlareSolverr cloudflare bypass" // { default = true; };
    unpackerr.enable = mkEnableOption "Unpackerr archive extractor" // { default = true; };
    navidrome.enable = mkEnableOption "Navidrome music server" // { default = true; };
  };
}
