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

    prowlarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prowlarr indexer manager";
      };
    };

    radarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Radarr movie management";
      };
    };

    sonarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Sonarr TV show management";
      };
    };

    lidarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Lidarr music management";
      };
    };

    readarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Readarr book management";
      };
    };

    listenarr = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Listenarr audiobook management";
      };
      publicUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Public URL for Listenarr (optional, used by Discord bot)";
        example = "https://listenarr.example.com";
      };
    };

    sabnzbd = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SABnzbd usenet downloader";
      };
    };

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

    jellyfin = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Jellyfin media server";
      };
    };

    jellyseerr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Jellyseerr request management";
      };
    };

    flaresolverr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable FlareSolverr cloudflare bypass";
      };
    };

    unpackerr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Unpackerr archive extractor";
      };
    };

    navidrome = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Navidrome music server";
      };
    };
  };
}
