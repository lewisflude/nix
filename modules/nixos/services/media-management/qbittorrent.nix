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
  # VPN namespace interface IP - VPN-Confinement typically assigns 192.168.15.1 to namespace interfaces
  vpnNamespaceIP = "192.168.15.1";
  # VPN WireGuard interface name and IP
  vpnInterfaceName = "qbittor0";
  vpnInterfaceIP = "10.2.0.2";
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

  config = mkIf (cfg.enable && qbittorrentCfg.enable) {
    services.qbittorrent = {
      enable = true;
      inherit (cfg) user group;
      webuiPort = 8080;
      torrentingPort = 6881;
      openFirewall = false; # VPN namespace handles firewall
      serverConfig = {
        # Bind WebUI to VPN network namespace address (always use VPN IP, not "*")
        Preferences = {
          WebUI = {
            Address = vpnNamespaceIP;
            Port = 8080;
            # WebUI access control - allow access from default network namespace and local network
            HostHeaderValidation = false;
            LocalHostAuth = false;
          }
          // optionalAttrs (webUI != null && webUI.username != null) {
            Username = webUI.username;
          }
          // optionalAttrs (webUI != null && webUI.password != null) {
            Password_PBKDF2 = webUI.password;
          };
          # Torrent queueing
          queueing_enabled = true;
          # Maximum active uploads (0 = infinite)
          max_active_uploads = 0;
          # Maximum active torrents (0 = infinite)
          max_active_torrents = 0;
          # Maximum active checking torrents (outstanding memory in MiB)
          checking_memory_use = 1;
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
        # Bind BitTorrent session to VPN interface
        BitTorrent = {
          Session = {
            Interface = vpnInterfaceName;
            InterfaceAddress = vpnInterfaceIP;
            InterfaceName = vpnInterfaceName;
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

    systemd.services.qbittorrent = {
      vpnConfinement = {
        enable = true;
        vpnNamespace = "qbittor";
      };
    };
  };
}
