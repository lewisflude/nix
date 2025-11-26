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

    # Kernel network tuning for high-bandwidth torrenting
    # Increases socket buffers to handle burst traffic from many concurrent connections
    boot.kernel.sysctl = {
      # Socket buffer configuration
      # Default: 212992 bytes (208 KB) - increased to 256 KB
      # Max: 33554432 bytes (32 MB) - kept at 32 MB
      "net.core.rmem_default" = 262144; # 256 KB receive buffer default
      "net.core.wmem_default" = 262144; # 256 KB send buffer default
      "net.core.rmem_max" = 33554432; # 32 MB receive buffer max (unchanged)
      "net.core.wmem_max" = 33554432; # 32 MB send buffer max (unchanged)

      # UDP buffer configuration for torrent traffic
      # Default: 4096 bytes - increased to 16 KB
      "net.ipv4.udp_rmem_min" = 16384; # 16 KB UDP receive buffer min
      "net.ipv4.udp_wmem_min" = 16384; # 16 KB UDP send buffer min

      # TCP congestion control for better VPN performance
      # BBR (Bottleneck Bandwidth and RTT) congestion control recommended for WireGuard VPN tunnels
      # Note: net.core.default_qdisc = "fq" and BBR IPv4/IPv6 are already configured in core/networking.nix
      "net.ipv4.tcp_congestion_control" = "bbr"; # BBR congestion control
    };

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
      # Add "MTU = 1420" to the [Interface] section of your WireGuard config
      # This value was determined by Path MTU Discovery (scripts/optimize-mtu.sh)
      # WireGuard + network overhead requires lower MTU to avoid packet fragmentation
      # Optimal MTU: 1420 (tested and verified)

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

        # NOTE: Custom nsswitch.conf is available at /etc/netns/${vpnCfg.namespace}/nsswitch.conf
        # but we don't bind-mount it due to NixOS store path issues after rebuilds.
        # The VPN namespace already has proper DNS configured via /etc/resolv.conf,
        # and the simplified nsswitch.conf is available if manual configuration is needed.
        #
        # If DNS issues occur, you can manually bind-mount with:
        # BindReadOnlyPaths = [ "/etc/netns/${vpnCfg.namespace}/nsswitch.conf:/etc/nsswitch.conf:norbind" ]
        # But be aware this may require `systemctl restart qbittorrent.service` after rebuilds.
        serviceConfig = {
          # Service will use default nsswitch.conf with DNS from VPN's resolv.conf
          # This is more robust across NixOS rebuilds than bind-mounting
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

      # Configure traffic control queue discipline on WireGuard interface
      # This prevents packet drops during traffic bursts from concurrent uploads
      "configure-qbt-qdisc" = {
        description = "Configure traffic control qdisc for qBittorrent WireGuard interface";
        after = [ "${vpnCfg.namespace}.service" ];
        before = [ "qbittorrent.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          # Remove default noqueue, add CAKE qdisc optimized for WireGuard
          # CAKE configuration:
          # - bandwidth 100mbit: Shape to 100 Mbit/s (headroom above 82 Mbit/s actual VPN speed)
          # - overhead 60: Account for WireGuard IPv4 encapsulation (20B IPv4 + 8B UDP + 32B WG = 60B)
          # - mpu 64: Minimum packet unit - accounts for WireGuard's cryptographic padding
          # - rtt 100ms: Default "internet" preset - conservative for worldwide torrent peers
          #              (Measured VPN RTT ~10ms, but peers can be 200ms+ globally)
          # Note: Start with conservative settings, can optimize to "metro" (rtt 10ms) later
          ExecStart = "${pkgs.iproute2}/bin/ip netns exec ${vpnCfg.namespace} ${pkgs.iproute2}/bin/tc qdisc replace dev ${vpnCfg.namespace}0 root cake bandwidth 100mbit overhead 60 mpu 64";
          # Clean up on stop
          ExecStop = "${pkgs.iproute2}/bin/ip netns exec ${vpnCfg.namespace} ${pkgs.iproute2}/bin/tc qdisc del dev ${vpnCfg.namespace}0 root || true";
        };
      };
    };
  };
}
