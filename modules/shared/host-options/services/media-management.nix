{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.host.features.mediaManagement = {
    enable = mkEnableOption "native media management services";

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
