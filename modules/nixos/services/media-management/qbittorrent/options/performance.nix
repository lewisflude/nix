{
  lib,
  ...
}:
{
  diskCacheSize = lib.mkOption {
    type = lib.types.int;
    default = 4096;
    description = "Disk cache size in MiB";
  };

  diskCacheTTL = lib.mkOption {
    type = lib.types.int;
    default = 60;
    description = "Disk cache TTL in seconds";
  };

  useOSCache = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Use OS page cache";
  };

  physicalMemoryLimit = lib.mkOption {
    type = lib.types.int;
    default = 8192;
    description = "Physical memory limit in MiB";
  };

  asyncIOThreadsCount = lib.mkOption {
    type = lib.types.int;
    default = 32;
    description = "Async I/O threads";
  };

  hashingThreadsCount = lib.mkOption {
    type = lib.types.int;
    default = 8;
    description = "Hash checking threads";
  };

  filePoolSize = lib.mkOption {
    type = lib.types.int;
    default = 10000;
    description = "File pool size";
  };

  checkingMemUsageSize = lib.mkOption {
    type = lib.types.int;
    default = 128;
    description = "Memory limit for hash checking in MiB";
  };

  ignoreSlowTorrents = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Don't count slow torrents in active limits";
  };

  slowTorrentsDownloadRate = lib.mkOption {
    type = lib.types.int;
    default = 5;
    description = "Slow torrent download threshold in KiB/s";
  };

  slowTorrentsUploadRate = lib.mkOption {
    type = lib.types.int;
    default = 5;
    description = "Slow torrent upload threshold in KiB/s";
  };

  slowTorrentsInactivityTimer = lib.mkOption {
    type = lib.types.int;
    default = 60;
    description = "Slow torrent timeout in seconds";
  };
}
