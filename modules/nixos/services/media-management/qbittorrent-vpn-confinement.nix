# VPN-Confinement configuration for qBittorrent
# Uses sops secret for WireGuard config file
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
  vpnEnabled = cfg.enable && cfg.qbittorrent.enable && cfg.qbittorrent.vpn.enable;

  # VPN namespace name (limited to 7 characters by VPN-Confinement)
  vpnNamespace = "qbittor"; # Max 7 chars, shortened from qbittorrent
  bittorrentPort = cfg.qbittorrent.bittorrent.port;
in {
  config = mkIf vpnEnabled {
    # VPN-Confinement namespace configuration
    vpnNamespaces.${vpnNamespace} = {
      enable = true;
      # Use sops secret path directly for WireGuard config file
      wireguardConfigFile = config.sops.secrets."vpn-confinement-qbittorrent".path;
      accessibleFrom = [
        "192.168.1.0/24" # Local network
        "192.168.0.0/24" # Additional local network
        "10.0.0.0/8" # Private networks
      ];
      portMappings = [
        {
          from = cfg.qbittorrent.webUI.port;
          to = cfg.qbittorrent.webUI.port;
          protocol = "tcp";
        }
        {
          from = bittorrentPort;
          to = bittorrentPort;
          protocol = "both";
        }
      ];
      # Open VPN ports for BitTorrent traffic
      openVPNPorts = [
        {
          port = bittorrentPort;
          protocol = "both";
        }
      ];
    };
  };
}
