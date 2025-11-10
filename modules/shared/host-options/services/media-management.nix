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

    qbittorrent = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable qBittorrent BitTorrent client";
      };

      webUI = {
        address = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "WebUI bind address. Use '*' or '0.0.0.0' to bind to all interfaces. Defaults to '*' when VPN is enabled.";
        };

        username = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "WebUI username.";
        };

        password = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "WebUI password (PBKDF2 hash in @ByteArray format).";
        };
      };

      categories = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Category path mappings. Maps category names to their save paths. Example: { movies = \"/mnt/storage/movies\"; tv = \"/mnt/storage/tv\"; }";
        example = {
          movies = "/mnt/storage/movies";
          tv = "/mnt/storage/tv";
          music = "/mnt/storage/music";
        };
      };

      bittorrent = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "BitTorrent configuration options";
      };

      connection = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Connection configuration options (DHT, PEX, etc.)";
      };

      bittorrentAdvanced = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Advanced BitTorrent configuration options";
      };

      vpn = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable VPN routing via network namespace";
        };

        interfaceName = mkOption {
          type = types.str;
          default = "wg-mullvad";
          description = "WireGuard interface name for VPN routing";
        };

        namespace = mkOption {
          type = types.str;
          default = "wg-qbittorrent";
          description = "Network namespace name for VPN isolation";
        };

        vethHostIP = mkOption {
          type = types.str;
          default = "10.200.200.1/24";
          description = "IP address for veth-host interface";
        };

        vethVPNIP = mkOption {
          type = types.str;
          default = "10.200.200.2/24";
          description = "IP address for veth-vpn interface";
        };
      };
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
