{
  lib,
  ...
}:
with lib;
{
  torrentPort = mkOption {
    type = types.port;
    default = 62000;
    description = "Port for BitTorrent traffic";
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

  ignoreLimitsOnLAN = mkOption {
    type = types.bool;
    default = true;
    description = ''
      Ignore upload/download rate limits for LAN transfers.
      Recommended: true to allow full-speed transfers within the local network.
    '';
  };
}
