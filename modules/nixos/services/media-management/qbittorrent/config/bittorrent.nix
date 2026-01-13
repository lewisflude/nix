{
  lib,
  qbittorrentCfg,
  webUICfg ? { },
  ...
}:
with lib;
let
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

  # BitTorrent Session configuration
  bittorrentSession = {
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
    # LSD (Local Peer Discovery) - disable when using VPN
    # It's only useful for finding peers on local LAN, which is irrelevant inside a VPN tunnel
    # When VPN is disabled, enable it for local network peer discovery
    UseLSD = if (qbittorrentCfg.vpn.enable or false) then false else true;

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
    # IMPORTANT: Disable IPv6 because ProtonVPN's NAT-PMP port forwarding is IPv4-only
    # Binding to IPv4 address ensures no IPv6 connections
    DisableIPv6 = true;
  }
  # Add DefaultSavePath to Session if configured
  // optionalAttrs (qbittorrentCfg.defaultSavePath != null) {
    DefaultSavePath = qbittorrentCfg.defaultSavePath;
  }
  # Add upload speed limit to Session if configured
  // optionalAttrs (qbittorrentCfg.uploadSpeedLimit != null) {
    GlobalUPSpeedLimit = qbittorrentCfg.uploadSpeedLimit;
  };
in
{
  inherit preferencesCfg;
  inherit bittorrentSession;
}
