# qBittorrent - Torrent client
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
  config = mkIf (cfg.enable && cfg.qbittorrent.enable) {
    services.qbittorrent = {
      enable = true;
      openFirewall = true;
      profileDir = "/var/lib/qbittorrent";
      webuiPort = 8080;
      torrentingPort = 6881;
      inherit (cfg) user;
      inherit (cfg) group;
      extraArgs = ["--confirm-legal-notice"];
      serverConfig = {
        LegalNotice.Accepted = true;
        Downloads = {
          SavePath = "${cfg.dataPath}/torrents";
          TempPathEnabled = false;
        };
      };
    };

    # Set timezone
    systemd.services.qbittorrent.environment = {
      TZ = cfg.timezone;
    };

    # Additional firewall rules for WebUI and torrent ports
    networking.firewall = {
      allowedTCPPorts = [
        8080 # WebUI
        6881 # BitTorrent
      ];
      allowedUDPPorts = [6881];
    };
  };
}
