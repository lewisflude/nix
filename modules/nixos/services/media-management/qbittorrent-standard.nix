{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalAttrs
    mapAttrs
    mkOverride
    optionalString
    ;
  cfg = config.host.services.mediaManagement;
  vpnEnabled = cfg.enable && cfg.qbittorrent.enable && cfg.qbittorrent.vpn.enable;

  vpnNamespace = "qbittor";

  webUIPort = cfg.qbittorrent.webUI.port or 8080;
  torrentingPort = (cfg.qbittorrent.bittorrent or { }).port or 6881;
in
{

  options.host.services.mediaManagement.qbittorrent = {
    enable = mkEnableOption "qBittorrent BitTorrent client" // {
      default = true;
    };

    webUI = {
      port = mkOption {
        type = types.port;
        default = 8080;
        description = "WebUI port.";
      };

      address = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "WebUI bind address. Use '*' or '0.0.0.0' to bind to all IPv4 interfaces. Defaults to '*' when VPN is enabled.";
      };

      username = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "WebUI username.";
      };

      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "WebUI password (PBKDF2 hash).";
      };
    };

    bittorrent = {
      port = mkOption {
        type = types.port;
        default = 6881;
        description = "Port for BitTorrent traffic.";
      };

      protocol = mkOption {
        type = types.enum [
          "TCP"
          "UDP"
          "Both"
        ];
        default = "TCP";
        description = "BitTorrent protocol to use.";
      };

      queueingEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable torrent queueing.";
      };

      maxActiveCheckingTorrents = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum number of active checking torrents.";
      };

      maxActiveUploads = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum number of active uploads (0 for unlimited).";
      };

      maxActiveTorrents = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum number of active torrents (0 for unlimited).";
      };

      diskCacheSize = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Disk cache size in MB.
          - Set to -1 to enable OS cache (uses RAM) - NOTE: May not work properly, showing 0 B buffer size
          - Set to 0 to disable cache (not recommended - major performance bottleneck)
          - Set to >0 for explicit cache size (recommended: 512-4096 MB for high-speed downloads)
          Recommended: Use explicit size (e.g., 2048 MB) instead of -1 for reliable cache performance.
        '';
      };

      maxConnections = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Global maximum number of connections.";
      };

      maxConnectionsPerTorrent = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum number of connections per torrent.";
      };

      maxUploads = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Global maximum number of upload slots.";
      };

      maxUploadsPerTorrent = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum number of upload slots per torrent.";
      };
    };

    connection = {
      dhtEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable DHT (Distributed Hash Table).";
      };

      pexEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable PEX (Peer Exchange).";
      };
    };

    bittorrentAdvanced = {
      utpMixedModeAlgorithm = mkOption {
        type = types.nullOr (
          types.enum [
            "TCP"
            "UTP"
            "Prefer TCP"
            "Prefer UTP"
          ]
        );
        default = null;
        description = "UTP-TCP Mixed Mode Algorithm.";
      };

      uploadSlotsBehavior = mkOption {
        type = types.nullOr (
          types.enum [
            "Fixed slots"
            "Upload rate based"
          ]
        );
        default = null;
        description = "Upload slots behaviour.";
      };

      uploadChokingAlgorithm = mkOption {
        type = types.nullOr (
          types.enum [
            "Round-robin"
            "Fastest upload"
            "Anti-leech"
          ]
        );
        default = null;
        description = "Upload choking algorithm.";
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

    vpn = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable VPN routing via network namespace.";
      };

      interfaceName = mkOption {
        type = types.str;
        default = "wg-mullvad";
        description = "WireGuard interface name for VPN routing.";
      };

      namespace = mkOption {
        type = types.str;
        default = "wg-qbittorrent";
        description = "Network namespace name for VPN isolation.";
      };

      vethHostIP = mkOption {
        type = types.str;
        default = "10.200.200.1/24";
        description = "IP address for veth-host interface.";
      };

      vethVPNIP = mkOption {
        type = types.str;
        default = "10.200.200.2/24";
        description = "IP address for veth-vpn interface.";
      };
    };
  };

  config = mkIf (cfg.enable && cfg.qbittorrent.enable) {

    users.users.qbittorrent.extraGroups = [ cfg.group ];

    systemd.tmpfiles.rules = [
      "d /var/lib/qBittorrent 0755 qbittorrent ${cfg.group} -"
      "d /var/lib/qBittorrent/config 0755 qbittorrent ${cfg.group} -"
      "d /var/lib/qBittorrent/data 0755 qbittorrent ${cfg.group} -"
      "d /var/lib/qBittorrent/logs 0755 qbittorrent ${cfg.group} -"
    ];

    services.qbittorrent = {
      enable = true;
      openFirewall = !vpnEnabled;
      webuiPort = webUIPort;
      inherit torrentingPort;

      profileDir = "/var/lib/qBittorrent";

      serverConfig = {
        LegalNotice.Accepted = true;

        Core = {

          AutoDeleteAddedTorrentFile = true;
        };

        Network = {
          # Disable UPnP/NAT-PMP when VPN is enabled - port forwarding is handled by
          # protonvpn-port-forwarding service using natpmpc directly to the gateway
          PortForwardingEnabled = !vpnEnabled;
        }
        // (
          if vpnEnabled then
            {
              InterfaceName = "qbittor0";
            }
          else
            { }
        );

        Preferences = {
          WebUI = {
            Enabled = true;
            Port = webUIPort;
            Address =
              if cfg.qbittorrent.webUI.address != null then
                cfg.qbittorrent.webUI.address
              else
                (if vpnEnabled then "*" else null);
          }
          // optionalAttrs (cfg.qbittorrent.webUI.username != null) {
            Username = cfg.qbittorrent.webUI.username;
          }
          // optionalAttrs (cfg.qbittorrent.webUI.password != null) {
            Password_PBKDF2 = cfg.qbittorrent.webUI.password;
          }
          // {

            AlternativeUIEnabled = true;
            RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";

            CSRFProtection = false;
          };

          Downloads = {

            Preallocation = true;

            SubcategoriesEnabled = true;

            DisableAutoTMMByDefault = false;

            DisableAutoTMMTriggersCategorySavePathChanged = false;

            DisableAutoTMMTriggersDefaultSavePathChanged = false;
          };

          Connection = {
            uTP_rate_limit_enabled = true;
            Bittorrent_rate_limit_utp = false;
            LimitLANPeers = true;
            DHTEnabled = (cfg.qbittorrent.connection or { }).dhtEnabled or true;
            PEXEnabled = (cfg.qbittorrent.connection or { }).pexEnabled or true;
          };

          Bittorrent = {
            Encryption = 1;
            AnonymousMode = false;
            UTPMixedModeAlgorithm =
              if (cfg.qbittorrent.bittorrentAdvanced or { }).utpMixedModeAlgorithm != null then
                (
                  if (cfg.qbittorrent.bittorrentAdvanced or { }).utpMixedModeAlgorithm == "TCP" then
                    0
                  else if (cfg.qbittorrent.bittorrentAdvanced or { }).utpMixedModeAlgorithm == "UTP" then
                    1
                  else if (cfg.qbittorrent.bittorrentAdvanced or { }).utpMixedModeAlgorithm == "Prefer TCP" then
                    2
                  else if (cfg.qbittorrent.bittorrentAdvanced or { }).utpMixedModeAlgorithm == "Prefer UTP" then
                    3
                  else
                    2
                )
              else
                2; # Default to "Prefer TCP"
            UploadSlotsBehavior =
              if (cfg.qbittorrent.bittorrentAdvanced or { }).uploadSlotsBehavior != null then
                (
                  if (cfg.qbittorrent.bittorrentAdvanced or { }).uploadSlotsBehavior == "Fixed slots" then
                    0
                  else if (cfg.qbittorrent.bittorrentAdvanced or { }).uploadSlotsBehavior == "Upload rate based" then
                    1
                  else
                    0
                )
              else
                0; # Default to "Fixed slots"
            UploadChokingAlgorithm =
              if (cfg.qbittorrent.bittorrentAdvanced or { }).uploadChokingAlgorithm != null then
                (
                  if (cfg.qbittorrent.bittorrentAdvanced or { }).uploadChokingAlgorithm == "Round-robin" then
                    0
                  else if (cfg.qbittorrent.bittorrentAdvanced or { }).uploadChokingAlgorithm == "Fastest upload" then
                    1
                  else if (cfg.qbittorrent.bittorrentAdvanced or { }).uploadChokingAlgorithm == "Anti-leech" then
                    2
                  else
                    1
                )
              else
                1; # Default to "Fastest upload"
          };

          Queueing = {

            MaxRatio = -1;

            MaxSeedingTime = -1;

            MaxRatioAction = 3;
          };
        };

        BitTorrent = {
          Session = {
            DefaultSavePath = "${cfg.dataPath}/torrents";
            TempPath = "${cfg.dataPath}/torrents/incomplete";
            FinishedTorrentExportDirectory = "${cfg.dataPath}/torrents/complete";
            BTProtocol = (cfg.qbittorrent.bittorrent or { }).protocol or "TCP";
            Preallocation = true;
            SubcategoriesEnabled = true;
            QueueingSystemEnabled = (cfg.qbittorrent.bittorrent or { }).queueingEnabled or true;
            MaxActiveCheckingTorrents = (cfg.qbittorrent.bittorrent or { }).maxActiveCheckingTorrents or 1;
            MaxActiveUploads = (cfg.qbittorrent.bittorrent or { }).maxActiveUploads or 0; # 0 = Infinite
            MaxActiveTorrents = (cfg.qbittorrent.bittorrent or { }).maxActiveTorrents or 0; # 0 = Infinite
            # Note: -1 (OS cache) may not work properly in some qBittorrent versions, showing 0 B buffer
            # Explicit cache size (e.g., 2048 MB) is recommended for reliable performance
            DiskCacheSize = (cfg.qbittorrent.bittorrent or { }).diskCacheSize or (-1); # -1 = Enable OS Cache (may not work)
            MaxConnections = (cfg.qbittorrent.bittorrent or { }).maxConnections or 2000;
            MaxConnectionsPerTorrent = (cfg.qbittorrent.bittorrent or { }).maxConnectionsPerTorrent or 200;
            MaxUploads = (cfg.qbittorrent.bittorrent or { }).maxUploads or 200;
            MaxUploadsPerTorrent = (cfg.qbittorrent.bittorrent or { }).maxUploadsPerTorrent or 5;
          }
          // (
            if vpnEnabled then
              {
                InterfaceName = "qbittor0";
              }
            else
              { }
          );
        };

        Category = mapAttrs (_: path: {
          SavePath = path;
        }) (cfg.qbittorrent.categories or { });
      };
    };

    systemd.services.qbittorrent = {

      preStart = ''


        if [ -d /var/lib/qBittorrent ]; then
          chown -R qbittorrent:${cfg.group} /var/lib/qBittorrent || true
        fi
      ''
      + optionalString vpnEnabled ''





        ${pkgs.iproute2}/bin/ip route add 10.2.0.1/32 dev qbittor0 2>/dev/null || true
      '';

      serviceConfig.Group = mkOverride 1000 cfg.group;
    }
    // optionalAttrs vpnEnabled {
      after = [ "network.target" ];

      vpnConfinement = {
        enable = true;
        inherit vpnNamespace;
      };
    };

  };
}
