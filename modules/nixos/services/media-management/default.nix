# Native NixOS Media Management Stack
# Uses official NixOS modules instead of containers
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;

  # Common settings for all media services
  commonUser = cfg.user;
  commonGroup = cfg.group;
  inherit (cfg) dataPath;
in {
  imports = [
    ./prowlarr.nix
    ./radarr.nix
    ./sonarr.nix
    ./lidarr.nix
    ./readarr.nix
    ./whisparr.nix
    ./qbittorrent.nix
    ./sabnzbd.nix
    ./jellyfin.nix
    ./jellyseerr.nix
    ./flaresolverr.nix
    ./unpackerr.nix
  ];

  options.host.services.mediaManagement = {
    enable = mkEnableOption "native media management stack";

    user = mkOption {
      type = types.str;
      default = "media";
      description = "User to run media services as";
    };

    group = mkOption {
      type = types.str;
      default = "media";
      description = "Group to run media services as";
    };

    dataPath = mkOption {
      type = types.str;
      default = "/mnt/storage";
      description = "Path to media storage directory";
    };

    timezone = mkOption {
      type = types.str;
      default = "Europe/London";
      description = "Timezone for all services";
    };

    # Service-specific enables
    prowlarr.enable = mkEnableOption "Prowlarr indexer manager" // {default = true;};
    radarr.enable = mkEnableOption "Radarr movie management" // {default = true;};
    sonarr.enable = mkEnableOption "Sonarr TV show management" // {default = true;};
    lidarr.enable = mkEnableOption "Lidarr music management" // {default = true;};
    readarr.enable = mkEnableOption "Readarr book management" // {default = true;};
    whisparr.enable = mkEnableOption "Whisparr adult content management" // {default = false;};
    qbittorrent.enable = mkEnableOption "qBittorrent torrent client" // {default = true;};
    sabnzbd.enable = mkEnableOption "SABnzbd usenet downloader" // {default = true;};
    jellyfin.enable = mkEnableOption "Jellyfin media server" // {default = true;};
    jellyseerr.enable = mkEnableOption "Jellyseerr request management" // {default = true;};
    flaresolverr.enable = mkEnableOption "FlareSolverr cloudflare bypass" // {default = true;};
    unpackerr.enable = mkEnableOption "Unpackerr archive extractor" // {default = true;};
  };

  config = mkIf cfg.enable {
    # Create common media user and group
    users.users.${commonUser} = {
      isSystemUser = true;
      group = commonGroup;
      description = "Media services user";
    };

    users.groups.${commonGroup} = {};

    # Ensure data directory exists and has correct permissions
    systemd.tmpfiles.rules = [
      "d ${dataPath} 0755 ${commonUser} ${commonGroup} -"
      "d ${dataPath}/media 0755 ${commonUser} ${commonGroup} -"
      "d ${dataPath}/media/movies 0755 ${commonUser} ${commonGroup} -"
      "d ${dataPath}/media/tv 0755 ${commonUser} ${commonGroup} -"
      "d ${dataPath}/media/music 0755 ${commonUser} ${commonGroup} -"
      "d ${dataPath}/media/books 0755 ${commonUser} ${commonGroup} -"
      "d ${dataPath}/torrents 0755 ${commonUser} ${commonGroup} -"
      "d ${dataPath}/usenet 0755 ${commonUser} ${commonGroup} -"
    ];
  };
}
