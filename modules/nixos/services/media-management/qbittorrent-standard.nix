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
    mkMerge
    types
    optionalAttrs
    mapAttrs
    mkOverride
    optionalString
    ;
  cfg = config.host.services.mediaManagement;
  vpnEnabled = cfg.enable && cfg.qbittorrent.enable && cfg.qbittorrent.vpn.enable;

  # Use configurable namespace, fallback to hardcoded value for backwards compatibility
  vpnNamespace = (cfg.qbittorrent.vpn or { }).namespace or "qbittor";
  # Interface name is derived from namespace (VPN-Confinement pattern: <namespace>0)
  vpnInterface = "${vpnNamespace}0";
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

      sslPort = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = "HTTPS port for BitTorrent traffic.";
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

      addExtensionToIncompleteFiles = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Add .!qB extension to incomplete files.";
      };

      globalDLSpeedLimit = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Global download speed limit in KiB/s (0 for unlimited).";
      };

      globalUPSpeedLimit = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Global upload speed limit in KiB/s (0 for unlimited).";
      };

      alternativeGlobalDLSpeedLimit = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Alternative global download speed limit in KiB/s (used when scheduler is active).";
      };

      alternativeGlobalUPSpeedLimit = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Alternative global upload speed limit in KiB/s (used when scheduler is active).";
      };

      useAlternativeGlobalSpeedLimit = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Use alternative global speed limits (typically for bandwidth scheduler).";
      };

      globalMaxRatio = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Global maximum ratio (-1 for unlimited, 2.0 means seed until 2x downloaded).";
      };

      globalMaxSeedingMinutes = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Global maximum seeding time in minutes (-1 for unlimited).";
      };

      globalMaxInactiveSeedingMinutes = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Global maximum inactive seeding time in minutes (-1 for unlimited).";
      };

      ignoreSlowTorrentsForQueueing = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Ignore slow torrents for queueing purposes.";
      };

      slowTorrentsDownloadRate = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Download rate threshold in KiB/s for considering a torrent slow.";
      };

      excludedFileNames = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Comma-separated list of file name patterns to exclude from downloads.";
      };

      bandwidthSchedulerEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable bandwidth scheduler.";
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

    core = {
      autoDeleteAddedTorrentFile = mkOption {
        type = types.nullOr (
          types.enum [
            "Never"
            "Always"
            "OnFailure"
          ]
        );
        default = null;
        description = "When to auto-delete added torrent files: Never, Always, or OnFailure.";
      };
    };

    application = {
      fileLogger = {
        enabled = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Enable file logging.";
        };

        path = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Path for log files.";
        };

        maxSizeBytes = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Maximum log file size in bytes.";
        };

        age = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Log file age in days.";
        };

        ageType = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Log file age type (0=days, 1=weeks, 2=months).";
        };

        backup = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Backup old log files before deletion.";
        };

        deleteOld = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Delete old log files.";
        };
      };

      memoryWorkingSetLimit = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Memory working set limit in MB (0 for unlimited).";
      };
    };

    preferences = {
      locale = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Locale for the UI (e.g., 'en', 'en_US').";
      };

      webUILocalHostAuth = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Require authentication for localhost WebUI access.";
      };

      mailNotification = {
        reqAuth = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Require authentication for mail notifications.";
        };
      };

      scheduler = {
        enabled = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Enable bandwidth scheduler.";
        };

        days = mkOption {
          type = types.nullOr (
            types.enum [
              "EveryDay"
              "Weekday"
              "Weekend"
            ]
          );
          default = null;
          description = "Days when scheduler is active: EveryDay, Weekday, or Weekend.";
        };

        startTime = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Scheduler start time in HH:MM format (24-hour).";
        };

        endTime = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Scheduler end time in HH:MM format (24-hour).";
        };
      };
    };

    rss = {
      autoDownloader = {
        downloadRepacks = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Auto-download repacks from RSS feeds.";
        };

        smartEpisodeFilter = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Smart episode filter regex pattern for RSS auto-downloader.";
        };
      };
    };

    vpn = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable VPN routing via VPN-Confinement network namespace.";
      };

      interfaceName = mkOption {
        type = types.str;
        default = "qbittor0";
        description = ''
          WireGuard interface name for VPN routing.
          Note: This is derived from the namespace as "<namespace>0" by VPN-Confinement.
          The interface is automatically created by VPN-Confinement.
        '';
      };

      namespace = mkOption {
        type = types.str;
        default = "qbittor";
        description = ''
          Network namespace name for VPN isolation.
          The interface name will be automatically set to "<namespace>0" (e.g., "qbittor0").
        '';
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

  config = mkIf (cfg.enable && cfg.qbittorrent.enable) (mkMerge [
    {
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
            AutoDeleteAddedTorrentFile =
              if (cfg.qbittorrent.core or { }).autoDeleteAddedTorrentFile != null then
                (
                  if (cfg.qbittorrent.core or { }).autoDeleteAddedTorrentFile == "Never" then
                    false
                  else if (cfg.qbittorrent.core or { }).autoDeleteAddedTorrentFile == "Always" then
                    true
                  else
                    true
                )
              else
                true; # Default to true (Always)
          };

          Application = optionalAttrs ((cfg.qbittorrent.application or { }) != { }) (
            {
            }
            // optionalAttrs ((cfg.qbittorrent.application.fileLogger or { }) != { }) {
              FileLogger = {
              }
              // optionalAttrs (cfg.qbittorrent.application.fileLogger.enabled != null) {
                Enabled = cfg.qbittorrent.application.fileLogger.enabled;
              }
              // optionalAttrs (cfg.qbittorrent.application.fileLogger.path != null) {
                Path = cfg.qbittorrent.application.fileLogger.path;
              }
              // optionalAttrs (cfg.qbittorrent.application.fileLogger.maxSizeBytes != null) {
                MaxSizeBytes = cfg.qbittorrent.application.fileLogger.maxSizeBytes;
              }
              // optionalAttrs (cfg.qbittorrent.application.fileLogger.age != null) {
                Age = cfg.qbittorrent.application.fileLogger.age;
              }
              // optionalAttrs (cfg.qbittorrent.application.fileLogger.ageType != null) {
                AgeType = cfg.qbittorrent.application.fileLogger.ageType;
              }
              // optionalAttrs (cfg.qbittorrent.application.fileLogger.backup != null) {
                Backup = cfg.qbittorrent.application.fileLogger.backup;
              }
              // optionalAttrs (cfg.qbittorrent.application.fileLogger.deleteOld != null) {
                DeleteOld = cfg.qbittorrent.application.fileLogger.deleteOld;
              };
            }
            // optionalAttrs (cfg.qbittorrent.application.memoryWorkingSetLimit != null) {
              MemoryWorkingSetLimit = cfg.qbittorrent.application.memoryWorkingSetLimit;
            }
          );

          Network = {
            # Disable UPnP/NAT-PMP when VPN is enabled - port forwarding is handled by
            # protonvpn-port-forwarding service using natpmpc directly to the gateway
            PortForwardingEnabled = !vpnEnabled;
          };

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
            // optionalAttrs ((cfg.qbittorrent.preferences or { }).webUILocalHostAuth != null) {
              LocalHostAuth = cfg.qbittorrent.preferences.webUILocalHostAuth;
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
              # Note: Interface binding is configured in BitTorrent.Session, not here
              InterfaceListenIPv6 = if vpnEnabled then false else null; # Disable IPv6 when VPN is enabled to prevent leaks
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

            General = optionalAttrs ((cfg.qbittorrent.preferences or { }).locale != null) {
              Locale = cfg.qbittorrent.preferences.locale;
            };

            MailNotification =
              optionalAttrs ((cfg.qbittorrent.preferences.mailNotification or { }).reqAuth != null)
                {
                  req_auth = cfg.qbittorrent.preferences.mailNotification.reqAuth;
                };

            Scheduler = optionalAttrs ((cfg.qbittorrent.preferences.scheduler or { }) != { }) (
              {
              }
              // optionalAttrs (cfg.qbittorrent.preferences.scheduler.enabled != null) {
                inherit (cfg.qbittorrent.preferences.scheduler) enabled;
              }
              // optionalAttrs (cfg.qbittorrent.preferences.scheduler.days != null) {
                inherit (cfg.qbittorrent.preferences.scheduler) days;
              }
              // optionalAttrs (cfg.qbittorrent.preferences.scheduler.startTime != null) {
                start_time = cfg.qbittorrent.preferences.scheduler.startTime;
              }
              // optionalAttrs (cfg.qbittorrent.preferences.scheduler.endTime != null) {
                end_time = cfg.qbittorrent.preferences.scheduler.endTime;
              }
            );
          };

          RSS = optionalAttrs ((cfg.qbittorrent.rss or { }) != { }) (
            {
            }
            // optionalAttrs ((cfg.qbittorrent.rss.autoDownloader or { }) != { }) {
              AutoDownloader = {
              }
              // optionalAttrs (cfg.qbittorrent.rss.autoDownloader.downloadRepacks != null) {
                DownloadRepacks = cfg.qbittorrent.rss.autoDownloader.downloadRepacks;
              }
              // optionalAttrs (cfg.qbittorrent.rss.autoDownloader.smartEpisodeFilter != null) {
                SmartEpisodeFilter = cfg.qbittorrent.rss.autoDownloader.smartEpisodeFilter;
              };
            }
          );

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
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).addExtensionToIncompleteFiles != null) {
              AddExtensionToIncompleteFiles = cfg.qbittorrent.bittorrent.addExtensionToIncompleteFiles;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).globalDLSpeedLimit != null) {
              GlobalDLSpeedLimit = cfg.qbittorrent.bittorrent.globalDLSpeedLimit;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).globalUPSpeedLimit != null) {
              GlobalUPSpeedLimit = cfg.qbittorrent.bittorrent.globalUPSpeedLimit;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).alternativeGlobalDLSpeedLimit != null) {
              AlternativeGlobalDLSpeedLimit = cfg.qbittorrent.bittorrent.alternativeGlobalDLSpeedLimit;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).alternativeGlobalUPSpeedLimit != null) {
              AlternativeGlobalUPSpeedLimit = cfg.qbittorrent.bittorrent.alternativeGlobalUPSpeedLimit;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).useAlternativeGlobalSpeedLimit != null) {
              UseAlternativeGlobalSpeedLimit = cfg.qbittorrent.bittorrent.useAlternativeGlobalSpeedLimit;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).globalMaxRatio != null) {
              GlobalMaxRatio = cfg.qbittorrent.bittorrent.globalMaxRatio;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).globalMaxSeedingMinutes != null) {
              GlobalMaxSeedingMinutes = cfg.qbittorrent.bittorrent.globalMaxSeedingMinutes;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).globalMaxInactiveSeedingMinutes != null) {
              GlobalMaxInactiveSeedingMinutes = cfg.qbittorrent.bittorrent.globalMaxInactiveSeedingMinutes;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).ignoreSlowTorrentsForQueueing != null) {
              IgnoreSlowTorrentsForQueueing = cfg.qbittorrent.bittorrent.ignoreSlowTorrentsForQueueing;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).slowTorrentsDownloadRate != null) {
              SlowTorrentsDownloadRate = cfg.qbittorrent.bittorrent.slowTorrentsDownloadRate;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).excludedFileNames != null) {
              ExcludedFileNames = cfg.qbittorrent.bittorrent.excludedFileNames;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).bandwidthSchedulerEnabled != null) {
              BandwidthSchedulerEnabled = cfg.qbittorrent.bittorrent.bandwidthSchedulerEnabled;
            }
            // optionalAttrs ((cfg.qbittorrent.bittorrent or { }).sslPort != null) {
              SSL = {
                Port = cfg.qbittorrent.bittorrent.sslPort;
              };
            }
            // optionalAttrs vpnEnabled {
              # Bind to VPN interface (only InterfaceName is used by qBittorrent)
              InterfaceName = vpnInterface;
              InterfaceAddress = ""; # Empty means use interface's IP
            };
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





          ${pkgs.iproute2}/bin/ip route add 10.2.0.1/32 dev ${vpnInterface} 2>/dev/null || true
        '';

        serviceConfig.Group = mkOverride 1000 cfg.group;
      }
      // optionalAttrs vpnEnabled {
        vpnConfinement = {
          enable = true;
          inherit vpnNamespace;
        };
      };
    }
    # VPN-Confinement configuration is handled by qbittorrent-vpn-confinement.nix
    # when vpnEnabled is true
  ]);

}
