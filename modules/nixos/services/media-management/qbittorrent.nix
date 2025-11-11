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
      default = 128;
      description = ''
        Disk cache size in MiB.
        - 0 = disabled
        - -1 = auto (qBittorrent decides)
        - >0 = fixed size in MiB
        Recommended: 64-128 MiB for good performance, up to 512 MiB for high-activity setups.
      '';
    };

    diskCacheTTL = mkOption {
      type = types.int;
      default = 60;
      description = "Disk cache TTL in seconds (how long to keep data in cache)";
    };
  };

  config = mkIf (cfg.enable && qbittorrentCfg.enable) {
    # Declare firewall rules for qBittorrent
    networking.firewall = {
      allowedTCPPorts = [
        8080
        6881
      ];

      # qBittorrent runs as the quarantine user (routes through VPN)
      # Add firewall mark for WebUI traffic to bypass VPN if wireguard-qbittorrent is enabled
      # This allows local access to the WebUI while torrent traffic stays on VPN
      extraCommands = mkIf config.services.wireguard-qbittorrent.enable ''
        iptables -t mangle -A OUTPUT -p tcp --sport 8080 -m owner --uid-owner quarantine -j MARK --set-mark ${toString config.services.wireguard-qbittorrent.webUIMark}
        ip6tables -t mangle -A OUTPUT -p tcp --sport 8080 -m owner --uid-owner quarantine -j MARK --set-mark ${toString config.services.wireguard-qbittorrent.webUIMark}
      '';
      extraStopCommands = mkIf config.services.wireguard-qbittorrent.enable ''
        iptables -t mangle -D OUTPUT -p tcp --sport 8080 -m owner --uid-owner quarantine -j MARK --set-mark ${toString config.services.wireguard-qbittorrent.webUIMark} || true
        ip6tables -t mangle -D OUTPUT -p tcp --sport 8080 -m owner --uid-owner quarantine -j MARK --set-mark ${toString config.services.wireguard-qbittorrent.webUIMark} || true
      '';
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
      # Run qBittorrent as the quarantine user (VPN routing) with media group (file access)
      user = "quarantine";
      group = "media";
      webuiPort = 8080;
      torrentingPort = 6881;
      openFirewall = false; # Firewall handled by WireGuard routing policy
      serverConfig = {
        # Bind WebUI to all interfaces (VPN routing is handled at network level)
        Preferences = {
          WebUI = {
            Address = "*";
            Port = 8080;
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
          # Maximum active uploads (0 = infinite)
          max_active_uploads = 0;
          # Maximum active torrents (0 = infinite)
          max_active_torrents = 0;
          # Maximum active checking torrents (outstanding memory in MiB)
          checking_memory_use = 1;
          # Disk cache size in MiB (0 = disabled, -1 = auto, >0 = fixed size)
          # Recommended: 64-128 MiB for good performance, up to 512 MiB for high-activity setups
          disk_cache = qbittorrentCfg.diskCacheSize or 128;
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
          max_connec = 2000;
          # Maximum number of connections per torrent
          max_connec_per_torrent = 200;
          # Global maximum number of upload slots
          max_uploads = 200;
          # Maximum number of upload slots per torrent
          max_uploads_per_torrent = 5;
        };
        # BitTorrent configuration (interface binding handled by routing policy)
        BitTorrent = {
          Session = {
            # Disable UPnP/NAT-PMP - we're using VPN port forwarding instead
            UseUPnP = false;
            UsePEX = true;
            UseDHT = true;
            # Torrent queueing system
            QueueingSystemEnabled = true;
            # Maximum active uploads (0 = infinite)
            MaxActiveUploads = 0;
            # Maximum active torrents (0 = infinite)
            MaxActiveTorrents = 0;
            # Global maximum number of connections
            MaxConnections = 2000;
            # Maximum number of connections per torrent
            MaxConnectionsPerTorrent = 200;
            # Global maximum number of upload slots
            MaxUploads = 200;
            # Maximum number of upload slots per torrent
            MaxUploadsPerTorrent = 5;
            # uTP-TCP mixed mode algorithm: Proportional (Peer proportional)
            # Rate limits TCP connections to their proportional share based on how many
            # connections are TCP, preventing uTP connections from being starved by TCP.
            # Values: "PreferTCP" or "Proportional"
            uTPMixedMode = "Proportional";
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
