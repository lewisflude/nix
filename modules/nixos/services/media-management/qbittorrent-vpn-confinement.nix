{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.host.services.mediaManagement;
  qbittorrentCfg = cfg.qbittorrent or { };
  vpnCfg = qbittorrentCfg.vpn or { };
in
{
  options.host.services.mediaManagement.qbittorrent.vpn = {
    enable = mkEnableOption "VPN namespace for qBittorrent";

    namespace = mkOption {
      type = types.str;
      default = "qbt";
      description = "Name of the VPN namespace (max 7 chars due to Linux interface name limit)";
    };

    wireguardConfig = mkOption {
      type = types.str;
      default = "vpn-confinement-qbittorrent";
      description = "SOPS secret name containing WireGuard configuration";
    };

    torrentPort = mkOption {
      type = types.port;
      default = 62000;
      description = "Port for BitTorrent traffic (will be updated by NAT-PMP)";
    };

    webUIBindAddress = mkOption {
      type = types.str;
      default = "192.168.1.210";
      description = "IP address to bind WebUI to on the host network";
    };
  };

  config = mkIf (cfg.enable && qbittorrentCfg.enable && vpnCfg.enable) {
    # Ensure VPN-Confinement module is available
    assertions = [
      {
        assertion = config.vpnNamespaces != null;
        message = "VPN-Confinement module is required but not available. Ensure vpn-confinement input is configured.";
      }
    ];

    # Configure SOPS secret for WireGuard configuration
    sops.secrets.${vpnCfg.wireguardConfig} = {
      restartUnits = [ "vpn-${vpnCfg.namespace}.service" ];
    };

    # Configure VPN namespace for qBittorrent
    vpnNamespaces.${vpnCfg.namespace} = {
      enable = true;

      # WireGuard configuration from SOPS
      wireguardConfigFile = config.sops.secrets.${vpnCfg.wireguardConfig}.path;

      # Allow access from main network (192.168.1.0/24)
      accessibleFrom = [
        "192.168.1.0/24"
      ];

      # Port forwarding for WebUI (host network ? namespace)
      portMappings = [
        {
          from = 8080;
          to = 8080;
        }
      ];

      # Open torrent port in VPN namespace
      openVPNPorts = [
        {
          port = vpnCfg.torrentPort;
          protocol = "both";
        }
      ];
    };

    # Add qBittorrent service to VPN namespace
    systemd.services.qbittorrent.vpnConfinement = {
      enable = true;
      vpnNamespace = vpnCfg.namespace;
    };
  };
}
