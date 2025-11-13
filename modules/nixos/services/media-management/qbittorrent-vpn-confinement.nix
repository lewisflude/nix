{
  config,
  lib,
  pkgs,
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

    # Ensure WireGuard tools and natpmpc are available
    # - wireguard-tools: required by VPN-Confinement startup script
    # - libnatpmp: required for ProtonVPN NAT-PMP port forwarding
    # - iproute2: required for ip command in NAT-PMP script
    environment.systemPackages = [
      pkgs.wireguard-tools
      pkgs.libnatpmp
      pkgs.iproute2
    ];

    # Configure SOPS secret for WireGuard configuration
    sops.secrets.${vpnCfg.wireguardConfig} = {
      restartUnits = [ "${vpnCfg.namespace}.service" ];
    };

    # Create custom nsswitch.conf for the namespace that bypasses systemd-resolved
    # This fixes DNS resolution by ensuring libc queries /etc/resolv.conf directly
    # instead of trying to use systemd-resolved (which is inaccessible due to security restrictions)
    environment.etc."netns/${vpnCfg.namespace}/nsswitch.conf".text = ''
      # Simplified NSS configuration for VPN namespace
      # Bypasses systemd-resolved and uses DNS directly from resolv.conf
      passwd:    files
      group:     files
      shadow:    files
      hosts:     files dns
      networks:  files
      ethers:    files
      services:  files
      protocols: files
      rpc:       files
    '';

    # Configure VPN namespace for qBittorrent
    vpnNamespaces.${vpnCfg.namespace} = {
      enable = true;

      # WireGuard configuration from SOPS
      wireguardConfigFile = config.sops.secrets.${vpnCfg.wireguardConfig}.path;

      # IMPORTANT: MTU must be configured in the WireGuard config file itself
      # Add "MTU = 1436" to the [Interface] section of your WireGuard config
      # Standard MTU (1500) + WireGuard overhead (64 bytes) would exceed link MTU
      # WireGuard typically needs 1436-1440 to avoid packet fragmentation

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

    # Configure systemd services for qBittorrent VPN
    systemd.services = {
      # Configure qBittorrent service for VPN namespace
      qbittorrent = {
        vpnConfinement = {
          enable = true;
          vpnNamespace = vpnCfg.namespace;
        };
        # Ensure qbittorrent service depends on network setup
        wants = [ "network-online.target" ];

        # Bind-mount custom nsswitch.conf to fix DNS resolution
        # This ensures the service uses the simplified NSS config that bypasses systemd-resolved
        serviceConfig = {
          BindReadOnlyPaths = [
            "/etc/netns/${vpnCfg.namespace}/nsswitch.conf:/etc/nsswitch.conf:norbind"
          ];
        };
      };

      # Add route to VPN gateway network for NAT-PMP connectivity
      # The WireGuard interface is point-to-point (/32), so we need an explicit
      # route to the gateway's subnet to ensure responses from 10.2.0.1 are properly routed back
      "configure-qbt-routes" = {
        description = "Configure routes for qBittorrent VPN namespace";
        after = [ "qbittorrent.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStart = "${pkgs.iproute2}/bin/ip netns exec ${vpnCfg.namespace} ${pkgs.iproute2}/bin/ip route add 10.2.0.0/24 dev ${vpnCfg.namespace}0";
          # Don't fail if route already exists
          SuccessExitStatus = [
            0
            2
          ];
        };
      };
    };
  };
}
