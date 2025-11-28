{
  config,
  lib,
  pkgs,
  constants,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    optionalAttrs
    mapAttrs
    ;
  cfg = config.host.services.mediaManagement;
  qbittorrentCfg = cfg.qbittorrent;
  inherit (qbittorrentCfg) webUI;
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
            alternativeUIEnabled = mkOption {
              type = types.bool;
              default = false;
              description = "Enable alternative WebUI (e.g., vuetorrent)";
            };
            rootFolder = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Root folder for alternative WebUI (absolute path). If null and alternativeUIEnabled is true, uses vuetorrent from Nix store";
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
      default = 4096;
      description = ''
        Disk cache size in MiB.
        - 0 = disabled
        - -1 = auto (qBittorrent decides)
        - >0 = fixed size in MiB
        Recommended: 512-1024 MiB for HDD-heavy setups with SSD incomplete staging.
        Default: 4096 MiB (4GB) for high-performance setups.
      '';
    };

    diskCacheTTL = mkOption {
      type = types.int;
      default = 60;
      description = "Disk cache TTL in seconds (how long to keep data in cache before flushing to disk)";
    };

    useOSCache = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Use OS page cache for disk I/O operations.
        Recommended: true for better performance with sufficient RAM.
      '';
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

    maxActiveDownloads = mkOption {
      type = types.int;
      default = 3;
      description = ''
        Maximum active downloads (torrents actively downloading).
        Recommended: 3-5 for residential connections to prevent download congestion.
        Higher values may cause HDD thrashing during concurrent writes.
      '';
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

    maxConnections = mkOption {
      type = types.int;
      default = 600;
      description = ''
        Global maximum number of connections.
        Recommended: 600 for stability (higher values may overwhelm routers/gateways).
        This value should remain at 600 regardless of upload speed for optimal router compatibility.
      '';
    };

    maxConnectionsPerTorrent = mkOption {
      type = types.int;
      default = 80;
      description = ''
        Maximum connections per torrent.
        Recommended: 80-100 (increase for better peer diversity on fast connections).
        Speed optimization: Set to 100 for upload speeds >5 MB/s (40 Mbit/s).
      '';
    };

    torrentPort = mkOption {
      type = types.port;
      default = 62000;
      description = "Port for BitTorrent traffic";
    };

    autoTMMEnabled = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable automatic torrent management (AutoTMM).
        Recommended: true for Arr apps to automatically use category-based save paths.
      '';
    };

    defaultSavePath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default folder for completed torrents (when AutoTMM is disabled or no category is set)";
    };

    maxRatio = mkOption {
      type = types.nullOr types.float;
      default = null;
      description = "Maximum seeding ratio (0 = unlimited, >0 = ratio limit). When reached, shareLimitAction is triggered";
    };

    maxSeedingTime = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Maximum seeding time in minutes (0 or null = unlimited).
        When reached, shareLimitAction is triggered.
        Note: This is an absolute time limit, not based on activity.
        Consider using maxInactiveSeedingTime instead.
      '';
    };

    maxInactiveSeedingTime = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Maximum inactive seeding time in minutes (0 or null = unlimited).
        Torrent is paused/removed after this many minutes of no upload activity.
        Recommended: 43200 (30 days) for automatic cleanup of dead torrents.
        This is more useful than maxSeedingTime as it only affects truly dead torrents.
      '';
    };

    shareLimitAction = mkOption {
      type = types.enum [
        "Stop"
        "Remove"
        "DeleteFiles"
      ];
      default = "Stop";
      description = ''
        Action when share limits (ratio or seeding time) are reached:
        - Stop: Pause torrent (can be resumed manually)
        - Remove: Remove torrent (files remain)
        - DeleteFiles: Remove torrent and delete files (dangerous with Radarr/Sonarr!)
      '';
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

    ipProtocol = mkOption {
      type = types.enum [
        "IPv4"
        "IPv6"
        "Both"
      ];
      default = "IPv4";
      description = ''
        IP protocol to use for BitTorrent connections:
        - IPv4: Use only IPv4 (recommended if IPv6 port forwarding doesn't work, or to prevent VPN leaks)
        - IPv6: Use only IPv6
        - Both: Use both IPv4 and IPv6 (may waste resources if IPv6 incoming doesn't work)
      '';
    };

    encryption = mkOption {
      type = types.enum [
        0
        1
        2
      ];
      default = 1;
      description = ''
        Protocol encryption mode:
        - 0: Prefer unencrypted connections (allow both encrypted and unencrypted)
        - 1: Require encryption (hide protocol headers from DPI, but allow legacy peers)
        - 2: Force encryption (only encrypted connections, may reduce peer pool)
        Recommended: 1 (require encryption) to prevent ISP throttling while maintaining peer pool.
      '';
    };

    addToTopOfQueue = mkOption {
      type = types.bool;
      default = true;
      description = "Add new torrents to the top of the queue";
    };

    addTorrentStopped = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Add new torrents in a stopped state (do not start automatically).
        Recommended: false for Arr apps to start downloads immediately.
      '';
    };

    preallocation = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Pre-allocate disk space for all files.
        CRITICAL: Must be false for ZFS/Btrfs to prevent massive fragmentation and double-writes.
      '';
    };

    addExtensionToIncompleteFiles = mkOption {
      type = types.bool;
      default = true;
      description = "Append .!qB extension to incomplete files";
    };

    useCategoryPathsInManualMode = mkOption {
      type = types.bool;
      default = true;
      description = "Use category paths even in manual torrent management mode";
    };

    ignoreLimitsOnLAN = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Ignore upload/download rate limits for LAN transfers.
        Recommended: true to allow full-speed transfers within the local network.
      '';
    };

    deleteTorrentFilesAfterwards = mkOption {
      type = types.enum [
        "Never"
        "Always"
        "IfAdded"
      ];
      default = "Never";
      description = ''
        Delete .torrent files after adding:
        - Never: Keep torrent files
        - Always: Always delete torrent files
        - IfAdded: Delete if torrent was successfully added
      '';
    };

    resumeDataSaveInterval = mkOption {
      type = types.int;
      default = 15;
      description = ''
        Interval in minutes to save resume data (fastresume files).
        Recommended: 15-30 minutes to prevent data loss on crashes.
        Default qBittorrent: 60 minutes.
      '';
    };

    reannounceWhenAddressChanged = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Reannounce to all trackers when IP or port changes.
        Critical for VPN setups - ensures trackers know about IP changes.
        Recommended: true (especially with VPN).
      '';
    };

    sendUploadPieceSuggestions = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Send upload piece suggestions to peers.
        Improves seeding efficiency by suggesting which pieces peers should request.
        Recommended: true for better upload performance.
      '';
    };

    utpTcpMixedMode = mkOption {
      type = types.enum [
        "TCP"
        "Proportional"
      ];
      default = "TCP";
      description = ''
        μTP-TCP mixed mode algorithm:
        - TCP: Prefer TCP connections (recommended for VPN and private trackers)
        - Proportional: Balance both protocols (may throttle TCP)
        For VPN users: TCP is more reliable and compatible.
      '';
    };

    physicalMemoryLimit = mkOption {
      type = types.int;
      default = 8192;
      description = ''
        Physical memory (RAM) usage limit in MiB for libtorrent >= 2.0.
        CRITICAL: Must match Application/MemoryWorkingSetLimit to prevent crashes when disk cache fills up.
        Recommended: 8192 MiB (8GB) for systems with 64GB+ RAM, 2048 MiB for 16GB RAM systems.
        This is separate from disk cache and controls overall libtorrent memory usage.
      '';
    };

    asyncIOThreadsCount = mkOption {
      type = types.int;
      default = 32;
      description = ''
        Number of async I/O threads for disk operations.
        Recommended: 32 for NVMe SSDs with high-performance CPUs (lower latency than 128).
        Default qBittorrent: 128 (too high even for i9, causes diminishing returns).
      '';
    };

    hashingThreadsCount = mkOption {
      type = types.int;
      default = 8;
      description = ''
        Number of threads for hash checking operations.
        Recommended: 8 for modern CPUs (matches P-core count on i9-13900K).
        Default qBittorrent: 32 (causes diminishing returns and context switching overhead).
      '';
    };

    filePoolSize = mkOption {
      type = types.int;
      default = 10000;
      description = "File pool size for managing open file handles";
    };

    coalesceReadWrite = mkOption {
      type = types.bool;
      default = true;
      description = "Coalesce read and write operations for better disk performance";
    };

    usePieceExtentAffinity = mkOption {
      type = types.bool;
      default = true;
      description = "Use piece extent affinity for better disk I/O performance";
    };

    sendBufferWatermark = mkOption {
      type = types.int;
      default = 512000;
      description = "Send buffer watermark in bytes (high watermark for TCP send buffer)";
    };

    sendBufferLowWatermark = mkOption {
      type = types.int;
      default = 1024;
      description = "Send buffer low watermark in bytes (low watermark for TCP send buffer)";
    };

    sendBufferWatermarkFactor = mkOption {
      type = types.int;
      default = 150;
      description = "Send buffer watermark factor (percentage multiplier for watermark calculation)";
    };

    checkingMemUsageSize = mkOption {
      type = types.int;
      default = 128;
      description = "Memory usage limit in MiB for hash checking operations";
    };

    ignoreSlowTorrents = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Do not count slow torrents in active torrent limits.
        When enabled, slow torrents don't count against MaxActiveTorrents and MaxActiveUploads limits.
        Useful for allowing active downloads/uploads to proceed without being blocked by idle seeding torrents.
        Recommended: true for systems with many seeding torrents.
      '';
    };

    slowTorrentsDownloadRate = mkOption {
      type = types.int;
      default = 5;
      description = ''
        Download rate threshold in KiB/s for considering a torrent "slow".
        A torrent downloading below this rate may be considered slow (if below threshold for SlowTorrentsInactivityTimer seconds).
        Recommended: 5 KiB/s (lower values may cause false positives).
      '';
    };

    slowTorrentsUploadRate = mkOption {
      type = types.int;
      default = 5;
      description = ''
        Upload rate threshold in KiB/s for considering a torrent "slow".
        A torrent uploading below this rate may be considered slow (if below threshold for SlowTorrentsInactivityTimer seconds).
        Recommended: 5 KiB/s (lower values may cause false positives).
      '';
    };

    slowTorrentsInactivityTimer = mkOption {
      type = types.int;
      default = 60;
      description = ''
        Time in seconds a torrent must be below the slow rate thresholds before being considered "slow".
        This prevents briefly idle torrents from being marked as slow.
        Recommended: 60 seconds (default qBittorrent value).
      '';
    };
  };

  config = mkIf (cfg.enable && qbittorrentCfg.enable) {
    # Firewall configuration
    # When VPN is enabled, only WebUI port needs to be open on host
    # When VPN is disabled, both WebUI and torrent ports need to be open
    networking.firewall = {
      allowedTCPPorts = [
        (if webUI != null then webUI.port else constants.ports.services.qbittorrent)
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
    systemd.services.qbittorrent.serviceConfig = {
      UMask = "0002";

      # CPU Scheduling: Use "batch" policy for smoother network throughput
      # Batch scheduling prevents qBittorrent from interrupting the networking stack
      # Nice=5 gives slightly lower priority than system processes (Nice=0)
      # but higher than background tasks (Nice=19)
      CPUSchedulingPolicy = "batch";
      Nice = 5;

      # I/O Scheduling: Best-effort with priority 5 (middle priority)
      # This prevents qBittorrent I/O from blocking Jellyfin streaming
      # but still prioritizes it over background tasks
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 5;
    };

    # Alternative UI support (vuetorrent)
    # No need to copy files - qBittorrent can read directly from Nix store
    environment.systemPackages = lib.optionals (webUI != null && webUI.alternativeUIEnabled) [
      pkgs.vuetorrent
    ];

    services.qbittorrent = {
      enable = true;
      # Run qBittorrent with media group for file access
      user = "qbittorrent";
      group = "media";
      webuiPort = if webUI != null then webUI.port else constants.ports.services.qbittorrent;
      torrentingPort = qbittorrentCfg.torrentPort;
      # Add --confirm-legal-notice flag to prevent service from exiting
      extraArgs = [ "--confirm-legal-notice" ];
      openFirewall = false; # Firewall handled explicitly above
      serverConfig =
        let
          # Build WebUI config cleanly
          webUICfg =
            if webUI != null then
              mkMerge [
                {
                  Address = webUI.bindAddress;
                  Port = webUI.port;
                  HostHeaderValidation = false;
                  LocalHostAuth = false;
                  AlternativeUIEnabled = webUI.alternativeUIEnabled;
                }
                (optionalAttrs (webUI.alternativeUIEnabled && webUI.rootFolder == null) {
                  RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
                })
                (optionalAttrs (webUI.rootFolder != null) {
                  RootFolder = webUI.rootFolder;
                })
                (optionalAttrs (webUI.username != null) {
                  Username =
                    if webUI.useSops then config.sops.secrets."qbittorrent/webui/username".path else webUI.username;
                })
                (optionalAttrs (webUI.password != null) {
                  Password_PBKDF2 =
                    if webUI.useSops then config.sops.secrets."qbittorrent/webui/password".path else webUI.password;
                })
              ]
            else
              { };

          # Build Preferences with optional fields
          # Note: Modern qBittorrent uses Session\ prefixed keys in [BitTorrent] section
          # This section includes WebUI config, AutoTMM, paths, ratio settings, and Advanced settings
          preferencesCfg = {
            AutoTMMEnabled = qbittorrentCfg.autoTMMEnabled;
            WebUI = webUICfg;
            # Advanced settings for libtorrent - nested under Advanced key
            Advanced = {
              PhysicalMemoryLimit = qbittorrentCfg.physicalMemoryLimit;
              SendUploadPieceSuggestions = qbittorrentCfg.sendUploadPieceSuggestions;
            };
          }
          // optionalAttrs (qbittorrentCfg.incompleteDownloadPath != null) {
            SavePath = qbittorrentCfg.incompleteDownloadPath;
          }
          // optionalAttrs (qbittorrentCfg.defaultSavePath != null) {
            DefaultSavePath = qbittorrentCfg.defaultSavePath;
          }
          // optionalAttrs (qbittorrentCfg.uploadSpeedLimit != null) {
            GlobalMaxUploadSpeed = qbittorrentCfg.uploadSpeedLimit;
          }
          // optionalAttrs (qbittorrentCfg.maxRatio != null) {
            MaxRatio = qbittorrentCfg.maxRatio;
          };
        in
        {
          Preferences = preferencesCfg;

          # Application configuration
          Application = {
            MemoryWorkingSetLimit = qbittorrentCfg.physicalMemoryLimit;
          };

          # Network configuration
          # PortForwardingEnabled is the master switch for UPnP/NAT-PMP in the WebUI
          # When VPN is enabled, disable port forwarding (handled by external NAT-PMP service)
          # When VPN is disabled, enable port forwarding for local router
          Network = {
            PortForwardingEnabled = if (qbittorrentCfg.vpn.enable or false) then false else true;
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
              UseLSD = true; # Local Peer Discovery - useful on LAN or extended network

              # IP Protocol selection (IPv4, IPv6, or Both)
              BTProtocol = qbittorrentCfg.ipProtocol;

              # Protocol encryption mode (hides BitTorrent protocol from DPI)
              # 0 = prefer unencrypted, 1 = require encryption (allow legacy), 2 = force encryption
              Encryption = qbittorrentCfg.encryption;

              # uTP/TCP mixed mode: TCP preferred for VPN, Proportional for balanced protocols
              # TCP is more reliable with VPNs and required by some private trackers
              uTPMixedMode = qbittorrentCfg.utpTcpMixedMode;

              # Torrent queueing system
              QueueingSystemEnabled = true;
              # Maximum active downloads (prevents download congestion)
              MaxActiveDownloads = qbittorrentCfg.maxActiveDownloads;
              # Maximum active uploads (optimized for HDD + Jellyfin streaming)
              MaxActiveUploads = qbittorrentCfg.maxActiveUploads;
              # Maximum active torrents (optimized for HDD capacity)
              MaxActiveTorrents = qbittorrentCfg.maxActiveTorrents;
              # Global maximum number of connections
              # Configurable via maxConnections option (default: 600 for router stability)
              MaxConnections = qbittorrentCfg.maxConnections;
              # Maximum number of connections per torrent
              # Configurable via maxConnectionsPerTorrent option (default: 80, recommended 100 for speed)
              MaxConnectionsPerTorrent = qbittorrentCfg.maxConnectionsPerTorrent;
              # Global maximum number of upload slots (optimized for balanced seeding)
              # Increased default to 300 for better slot allocation across many torrents
              MaxUploads = qbittorrentCfg.maxUploads;
              # Maximum number of upload slots per torrent (improved from 5 to 10)
              MaxUploadsPerTorrent = qbittorrentCfg.maxUploadsPerTorrent;

              # Additional torrent behavior settings
              AddTorrentToTopOfQueue = qbittorrentCfg.addToTopOfQueue;
              Preallocation = qbittorrentCfg.preallocation;
              AddExtensionToIncompleteFiles = qbittorrentCfg.addExtensionToIncompleteFiles;
              UseCategoryPathsInManualMode = qbittorrentCfg.useCategoryPathsInManualMode;

              # Resume data save interval (minutes)
              SaveResumeDataInterval = qbittorrentCfg.resumeDataSaveInterval;

              # Upload piece suggestions for better seeding
              SuggestMode = qbittorrentCfg.sendUploadPieceSuggestions;

              # Tracker announce settings
              AnnounceToAllTrackers = qbittorrentCfg.reannounceWhenAddressChanged;
              ReannounceWhenAddressChanged = qbittorrentCfg.reannounceWhenAddressChanged;

              # Advanced session settings for performance optimization
              AsyncIOThreadsCount = qbittorrentCfg.asyncIOThreadsCount;
              HashingThreadsCount = qbittorrentCfg.hashingThreadsCount;
              FilePoolSize = qbittorrentCfg.filePoolSize;
              DiskCacheSize = qbittorrentCfg.diskCacheSize;
              DiskCacheTTL = qbittorrentCfg.diskCacheTTL;
              CoalesceReadWrite = qbittorrentCfg.coalesceReadWrite;
              PieceExtentAffinity = qbittorrentCfg.usePieceExtentAffinity;
              SendBufferWatermark = qbittorrentCfg.sendBufferWatermark;
              SendBufferLowWatermark = qbittorrentCfg.sendBufferLowWatermark;
              SendBufferWatermarkFactor = qbittorrentCfg.sendBufferWatermarkFactor;
              CheckingMemUsageSize = qbittorrentCfg.checkingMemUsageSize;

              # OS cache usage for better performance with sufficient RAM
              use_os_cache = qbittorrentCfg.useOSCache;

              # LAN rate limit bypass
              IgnoreLimitsOnLAN = qbittorrentCfg.ignoreLimitsOnLAN;

              # Torrent start behavior
              AddTorrentStopped = qbittorrentCfg.addTorrentStopped;

              # Slow torrent handling - don't count slow torrents in active limits
              IgnoreSlowTorrents = qbittorrentCfg.ignoreSlowTorrents;
              IgnoreSlowTorrentsForQueueing = qbittorrentCfg.ignoreSlowTorrents;
              SlowTorrentsDownloadRate = qbittorrentCfg.slowTorrentsDownloadRate;
              SlowTorrentsUploadRate = qbittorrentCfg.slowTorrentsUploadRate;
              SlowTorrentsInactivityTimer = qbittorrentCfg.slowTorrentsInactivityTimer;

              # Share limits (ratio and seeding time limits)
              # GlobalMaxRatio and GlobalMaxInactiveSeedingMinutes are in Session, not Preferences
              ShareLimitAction = qbittorrentCfg.shareLimitAction;
            }
            // optionalAttrs (qbittorrentCfg.maxRatio != null) {
              GlobalMaxRatio = qbittorrentCfg.maxRatio;
            }
            // optionalAttrs (qbittorrentCfg.maxSeedingTime != null) {
              GlobalMaxSeedingMinutes = qbittorrentCfg.maxSeedingTime;
            }
            // optionalAttrs (qbittorrentCfg.maxInactiveSeedingTime != null) {
              GlobalMaxInactiveSeedingMinutes = qbittorrentCfg.maxInactiveSeedingTime;
            }
            # VPN Interface binding - ONLY when VPN is enabled
            # This ensures all BitTorrent traffic uses the VPN interface
            // optionalAttrs (qbittorrentCfg.vpn.enable or false) {
              Interface = "qbt0";
              InterfaceName = "qbt0";
              InterfaceAddress = "10.2.0.2";
              # Note: AnnounceIP is left unset to allow auto-detection
              # The tracker will see the VPN's public IP from the connection
            }
            # Add DefaultSavePath to Session if configured
            // optionalAttrs (qbittorrentCfg.defaultSavePath != null) {
              DefaultSavePath = qbittorrentCfg.defaultSavePath;
            }
            # Add upload speed limit to Session if configured
            // optionalAttrs (qbittorrentCfg.uploadSpeedLimit != null) {
              GlobalUPSpeedLimit = qbittorrentCfg.uploadSpeedLimit;
            };
          };
        }
        # Core configuration - at same level as BitTorrent and Preferences
        // optionalAttrs (qbittorrentCfg.deleteTorrentFilesAfterwards != "Never") {
          Core = {
            AutoDeleteAddedTorrentFile = qbittorrentCfg.deleteTorrentFilesAfterwards;
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
