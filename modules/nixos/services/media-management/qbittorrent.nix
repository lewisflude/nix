{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    optionalAttrs
    mapAttrs
    ;
  cfg = config.host.services.mediaManagement;
  qbittorrentCfg = cfg.qbittorrent or { };
  webUI = qbittorrentCfg.webUI or null;
  constants = import ../../../../lib/constants.nix;
in
{
  options.host.services.mediaManagement.qbittorrent = {
    enable = mkEnableOption "qBittorrent BitTorrent client" // {
      default = true;
    };

    webUI = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            username = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "WebUI username (plain text or SOPS secret path)";
            };
            password = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "WebUI password (PBKDF2 format, plain text or SOPS secret path)";
            };
            useSops = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to use SOPS secrets for WebUI credentials";
            };
            port = mkOption {
              type = types.port;
              default = constants.ports.services.qbittorrent;
              description = "WebUI port";
            };
            bindAddress = mkOption {
              type = types.str;
              default = "*";
              description = "WebUI bind address (* for all interfaces, or specific IP)";
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

    diskCacheSize = mkOption {
      type = types.int;
      default = 512;
      description = ''
        Disk cache size in MiB.
        - 0 = disabled
        - -1 = auto (qBittorrent decides)
        - >0 = fixed size in MiB
        Recommended: 512-1024 MiB for HDD-heavy setups with SSD incomplete staging.
      '';
    };

    diskCacheTTL = mkOption {
      type = types.int;
      default = 60;
      description = "Disk cache TTL in seconds (how long to keep data in cache)";
    };

    incompleteDownloadPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Path to store incomplete downloads.
        Recommended: Fast SSD path (e.g., /mnt/nvme/qbittorrent/incomplete) for staging before Radarr/Sonarr moves to final location.
        Final download paths are configured per-category.
      '';
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
      default = 300;
      description = "Maximum upload slots (recommended: 300 for better slot allocation across many torrents)";
    };

    maxUploadsPerTorrent = mkOption {
      type = types.int;
      default = 10;
      description = "Maximum upload slots per torrent (recommended: 10 to improve seeding)";
    };

    torrentPort = mkOption {
      type = types.port;
      default = 62000;
      description = "Port for BitTorrent traffic";
    };
  };

  config = mkIf (cfg.enable && qbittorrentCfg.enable) {
    # Firewall configuration
    # When VPN is enabled, only WebUI port needs to be open on host
    # When VPN is disabled, both WebUI and torrent ports need to be open
    networking.firewall = {
      allowedTCPPorts = [
        (webUI.port or constants.ports.services.qbittorrent)
      ] # WebUI always accessible
      ++ lib.optionals (!(qbittorrentCfg.vpn.enable or false)) [
        qbittorrentCfg.torrentPort # Torrent port only when VPN disabled
      ];
      allowedUDPPorts = lib.optionals (!(qbittorrentCfg.vpn.enable or false)) [
        qbittorrentCfg.torrentPort # Torrent port only when VPN disabled
      ];
    };

    # SOPS secrets for WebUI credentials
    sops.secrets = mkIf (webUI != null && webUI.useSops) {
      "qbittorrent/webui/username" = {
        neededForUsers = true;
      };
      "qbittorrent/webui/password" = {
        neededForUsers = true;
      };
    };

    # Set umask for qBittorrent service to ensure group-writable files
    systemd.services.qbittorrent.serviceConfig.UMask = "0002";

    services.qbittorrent = {
      enable = true;
      # Run qBittorrent with media group for file access
      user = "qbittorrent";
      group = "media";
      webuiPort = webUI.port or constants.ports.services.qbittorrent;
      torrentingPort = qbittorrentCfg.torrentPort;
      # Add --confirm-legal-notice flag to prevent service from exiting
      extraArgs = [ "--confirm-legal-notice" ];
      openFirewall = false; # Firewall handled explicitly above
      serverConfig = {
        Preferences = {
          # Connection settings - NO explicit binding in VPN namespace
          # The namespace itself constrains all traffic through VPN
          Connection = { };
          # Storage settings - staging incomplete on SSD, final on HDD via categories
          Saving = optionalAttrs (qbittorrentCfg.incompleteDownloadPath != null) {
            SavePath = qbittorrentCfg.incompleteDownloadPath;
          };
          WebUI = {
            # Bind WebUI to specified address or all interfaces
            Address = webUI.bindAddress or "*";
            Port = webUI.port or constants.ports.services.qbittorrent;
            # WebUI access control
            HostHeaderValidation = false;
            LocalHostAuth = false;
          }
          // optionalAttrs (webUI != null && webUI.username != null) {
            Username =
              if webUI.useSops then config.sops.secrets."qbittorrent/webui/username".path else webUI.username;
          }
          // optionalAttrs (webUI != null && webUI.password != null) {
            Password_PBKDF2 =
              if webUI.useSops then config.sops.secrets."qbittorrent/webui/password".path else webUI.password;
          };
          # Torrent queueing
          queueing_enabled = true;
          # Maximum active uploads (optimized for HDD + Jellyfin streaming)
          max_active_uploads = qbittorrentCfg.maxActiveUploads or 75;
          # Maximum active torrents (optimized for HDD capacity)
          max_active_torrents = qbittorrentCfg.maxActiveTorrents or 150;
          # Maximum active checking torrents (outstanding memory in MiB)
          checking_memory_use = 1;
          # Disk cache size in MiB (0 = disabled, -1 = auto, >0 = fixed size)
          # Optimized for SSD staging of incomplete downloads
          disk_cache = qbittorrentCfg.diskCacheSize or 512;
          # Disk cache TTL in seconds (how long to keep data in cache)
          disk_cache_ttl = qbittorrentCfg.diskCacheTTL or 60;
          # uTP-TCP mixed mode algorithm: 1 = Peer proportional
          # Rate limits TCP connections to their proportional share based on how many
          # connections are TCP, preventing uTP connections from being starved by TCP.
          # Values: 0 = Prefer TCP, 1 = Peer proportional
          utp_tcp_mixed_mode = 1;
          # Upload slots behaviour: 0 = Fixed slots
          # Values: 0 = Fixed slots, 1 = Upload rate based
          upload_slots_behavior = 0;
          # Upload choking algorithm: 1 = Fastest upload
          # Values: 0 = Round-robin, 1 = Fastest upload, 2 = Anti-leech
          upload_choking_algorithm = 1;
          # Global maximum number of connections
          # Optimized: Reduced from 2000 to 600 to prevent router/gateway overload
          # and reduce VPN namespace overhead while still supporting 150 active torrents
          max_connec = 600;
          # Maximum number of connections per torrent
          # Optimized: Reduced from 200 to 80 for better peer management
          max_connec_per_torrent = 80;
          # Global maximum number of upload slots (optimized for balanced seeding)
          max_uploads = qbittorrentCfg.maxUploads or 300;
          # Maximum number of upload slots per torrent (improved from 5 to 10)
          max_uploads_per_torrent = qbittorrentCfg.maxUploadsPerTorrent or 10;
          # Advanced libtorrent buffer settings for better throughput
          # Send buffer watermark: 1024 KB (1 MB) reduces pipeline stalls during uploads
          send_buf_watermark = 1024;
          # Send buffer low watermark: 128 KB minimum buffer target for good seeding
          send_buf_low_watermark = 128;
        };
        # BitTorrent configuration
        BitTorrent = {
          Session = {
            Port = qbittorrentCfg.torrentPort;

            # Automatic port forwarding (disabled in VPN mode)
            # When VPN is enabled, UPnP and NAT-PMP are disabled because:
            # 1. VPN gateways don't support these protocols
            # 2. External NAT-PMP automation (protonvpn-portforward.service) handles port forwarding
            # 3. This prevents "no router found" errors in logs
            # When VPN is disabled, enable UPnP for automatic port forwarding on local router
            UseUPnP = if (qbittorrentCfg.vpn.enable or false) then false else true;
            UseNATPMP = if (qbittorrentCfg.vpn.enable or false) then false else true;

            # Protocol settings
            UsePEX = true; # Peer exchange for better peer discovery
            UseDHT = true; # DHT for trackerless torrents

            # uTP/TCP mixed mode: Proportional balances both protocols
            # Prevents TCP from starving uTP connections
            uTPMixedMode = "Proportional";

            # Torrent queueing system
            QueueingSystemEnabled = true;
            # Maximum active uploads (optimized for HDD + Jellyfin streaming)
            MaxActiveUploads = qbittorrentCfg.maxActiveUploads or 75;
            # Maximum active torrents (optimized for HDD capacity)
            MaxActiveTorrents = qbittorrentCfg.maxActiveTorrents or 150;
            # Global maximum number of connections
            # Optimized: Reduced from 2000 to 600 to prevent router/gateway overload
            MaxConnections = 600;
            # Maximum number of connections per torrent
            # Optimized: Reduced from 200 to 80 for better peer management
            MaxConnectionsPerTorrent = 80;
            # Global maximum number of upload slots (optimized for balanced seeding)
            # Increased default to 300 for better slot allocation across many torrents
            MaxUploads = qbittorrentCfg.maxUploads or 300;
            # Maximum number of upload slots per torrent (improved from 5 to 10)
            MaxUploadsPerTorrent = qbittorrentCfg.maxUploadsPerTorrent or 10;
          }
          # VPN Interface binding - ONLY when VPN is enabled
          # This ensures all BitTorrent traffic uses the VPN interface
          // optionalAttrs (qbittorrentCfg.vpn.enable or false) {
            Interface = "qbt0";
            InterfaceName = "qbt0";
            InterfaceAddress = "10.2.0.2";
          };
        };
      }
      // optionalAttrs (qbittorrentCfg.categories != null) {
        Category = mapAttrs (_: path: {
          SavePath = path;
        }) qbittorrentCfg.categories;
      };
    };

  };
}
