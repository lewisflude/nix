{
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
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
    description = "IP protocol for BitTorrent connections";
  };

  encryption = mkOption {
    type = types.enum [
      0
      1
      2
    ];
    default = 1;
    description = "Protocol encryption (0=prefer unencrypted, 1=require, 2=force)";
  };

  utpTcpMixedMode = mkOption {
    type = types.enum [
      "TCP"
      "Proportional"
    ];
    default = "TCP";
    description = "μTP-TCP mixed mode (TCP preferred for VPN)";
  };

  maxConnections = mkOption {
    type = types.int;
    default = 600;
    description = "Global maximum connections";
  };

  maxConnectionsPerTorrent = mkOption {
    type = types.int;
    default = 80;
    description = "Maximum connections per torrent";
  };

  maxActiveTorrents = mkOption {
    type = types.int;
    default = 150;
    description = "Maximum active torrents";
  };

  maxActiveDownloads = mkOption {
    type = types.int;
    default = 3;
    description = "Maximum active downloads";
  };

  maxActiveUploads = mkOption {
    type = types.int;
    default = 75;
    description = "Maximum active uploads";
  };

  maxUploads = mkOption {
    type = types.int;
    default = 300;
    description = "Maximum upload slots";
  };

  maxUploadsPerTorrent = mkOption {
    type = types.int;
    default = 10;
    description = "Maximum upload slots per torrent";
  };

  addToTopOfQueue = mkOption {
    type = types.bool;
    default = true;
    description = "Add new torrents to top of queue";
  };

  addTorrentStopped = mkOption {
    type = types.bool;
    default = false;
    description = "Add new torrents in stopped state";
  };

  reannounceWhenAddressChanged = mkOption {
    type = types.bool;
    default = true;
    description = "Reannounce to trackers when IP/port changes (critical for VPN)";
  };

  sendUploadPieceSuggestions = mkOption {
    type = types.bool;
    default = true;
    description = "Send upload piece suggestions to peers";
  };

  ignoreLimitsOnLAN = mkOption {
    type = types.bool;
    default = true;
    description = "Ignore rate limits for LAN transfers";
  };
}
