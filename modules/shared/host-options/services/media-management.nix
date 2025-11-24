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
    };

    timezone = mkOption {
      type = types.str;
      default = "Europe/London";
      description = "Timezone for media services";
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
      type = types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable qBittorrent BitTorrent client";
          };
          incompleteDownloadPath = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Path to store incomplete downloads (recommended: fast SSD for staging before Radarr/Sonarr moves to final location)";
          };
          diskCacheSize = mkOption {
            type = types.int;
            default = 512;
            description = "Disk cache size in MiB (recommended: 512-1024 for HDD-heavy setups with SSD incomplete staging)";
          };
          diskCacheTTL = mkOption {
            type = types.int;
            default = 60;
            description = "Disk cache TTL in seconds";
          };
          maxActiveTorrents = mkOption {
            type = types.int;
            default = 150;
            description = "Maximum active torrents (recommended: 150 for HDD-based storage to avoid saturation)";
          };
          maxActiveUploads = mkOption {
            type = types.int;
            default = 75;
            description = "Maximum active uploads (recommended: 75 to prevent HDD thrashing with Jellyfin streaming)";
          };
          maxUploads = mkOption {
            type = types.int;
            default = 150;
            description = "Maximum upload slots (recommended: 150 for balanced seeding)";
          };
          maxUploadsPerTorrent = mkOption {
            type = types.int;
            default = 10;
            description = "Maximum upload slots per torrent (recommended: 10 to improve seeding)";
          };
          uploadSpeedLimit = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              Upload speed limit in KB/s (recommended: ~80% of upload capacity).
              Set to null for unlimited. Use speedtest.net to determine your upload speed in kB/s,
              then set this to approximately 80% of that value to allow room for outgoing communications.
            '';
          };
          autoTMMEnabled = mkOption {
            type = types.bool;
            default = false;
            description = "Enable automatic torrent management (AutoTMM)";
          };
          defaultSavePath = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Default folder for completed torrents (when AutoTMM is disabled or no category is set)";
          };
          maxRatio = mkOption {
            type = types.nullOr types.float;
            default = null;
            description = "Maximum seeding ratio (0 = unlimited, >0 = ratio limit). When reached, MaxRatioAction is triggered";
          };
          maxRatioAction = mkOption {
            type = types.int;
            default = 0;
            description = "Action when max ratio is reached: 0 = pause torrent, 1 = remove torrent, 2 = remove torrent with files";
          };
          vpn = mkOption {
            type = types.nullOr (
              types.submodule {
                options = {
                  enable = mkOption {
                    type = types.bool;
                    default = false;
                    description = "Enable VPN namespace for qBittorrent";
                  };
                  namespace = mkOption {
                    type = types.str;
                    default = "qbt";
                    description = "VPN namespace name (max 7 chars)";
                  };
                  torrentPort = mkOption {
                    type = types.port;
                    default = 62000;
                    description = "BitTorrent port";
                  };
                  webUIBindAddress = mkOption {
                    type = types.str;
                    default = "*";
                    description = "WebUI bind address";
                  };
                };
              }
            );
            default = null;
            description = "VPN configuration";
          };
          webUI = mkOption {
            type = types.nullOr (
              types.submodule {
                options = {
                  port = mkOption {
                    type = types.port;
                    default = 8080;
                    description = "WebUI port";
                  };
                  bindAddress = mkOption {
                    type = types.str;
                    default = "*";
                    description = "WebUI bind address";
                  };
                  username = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "WebUI username";
                  };
                  password = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "WebUI password (PBKDF2 format)";
                  };
                  alternativeUIEnabled = mkOption {
                    type = types.bool;
                    default = false;
                    description = "Enable alternative WebUI (e.g., vuetorrent)";
                  };
                  rootFolder = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Root folder for alternative WebUI (absolute path). If null and alternativeUIEnabled is true, defaults to vuetorrent package path";
                  };
                };
              }
            );
            default = null;
            description = "WebUI configuration";
          };
          categories = mkOption {
            type = types.nullOr (types.attrsOf types.str);
            default = null;
            description = "Category save paths";
          };
        };
      };
      default = { };
      description = "qBittorrent configuration";
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
