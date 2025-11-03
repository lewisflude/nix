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
  bittorrentPort = (cfg.qbittorrent.bittorrent or {}).port or 6881;
in {
  config = mkIf vpnEnabled {
    # VPN-Confinement namespace configuration
    vpnNamespaces.${vpnNamespace} = {
      enable = true;
      # Use sops secret path directly for WireGuard config file
      wireguardConfigFile = config.sops.secrets."vpn-confinement-qbittorrent".path;
      accessibleFrom = [
        "127.0.0.1/32" # Localhost
        "::1/128" # IPv6 localhost
        "192.168.1.0/24" # Local network
        "192.168.0.0/24" # Additional local network
        "10.0.0.0/8" # Private networks
      ];
      portMappings = [
        {
          # Standard NixOS module defaults to 8080, so map both ports
          # Use 8080 as the default since that's what the standard module uses
          #
          # IMPORTANT: Access qBittorrent WebUI via bridge gateway IP, not localhost:
          # - ✅ Works: http://192.168.15.1:8080/ (bridge gateway IP)
          # - ❌ Doesn't work: http://localhost:8080 (bypasses bridge NAT rules)
          #
          # Localhost traffic routes through loopback interface, bypassing the bridge
          # where VPN-Confinement's NAT rules are applied. The bridge gateway IP
          # (192.168.15.1) is the correct way to access services in VPN-Confinement namespaces.
          from = cfg.qbittorrent.webUI.port or 8080;
          to = cfg.qbittorrent.webUI.port or 8080;
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
