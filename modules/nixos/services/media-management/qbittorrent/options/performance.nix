{
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
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
}
