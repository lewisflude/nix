{
  lib,
  constants,
  ...
}:
with lib;
let
  qbittorrentOptions = {
    enable = mkEnableOption "qBittorrent BitTorrent client" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for qBittorrent" // {
      default = true;
    };

    categories = mkOption {
      type = types.nullOr (types.attrsOf types.str);
      default = null;
      description = "Category save paths";
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
  };
in
{
  options.host.services.mediaManagement.qbittorrent =
    qbittorrentOptions
    // (import ./webui.nix { inherit lib constants; })
    // (import ./bittorrent.nix { inherit lib; })
    // (import ./performance.nix { inherit lib; });
}
