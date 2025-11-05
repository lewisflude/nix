# VPN-Confinement configuration for qBittorrent
# Uses sops secret for WireGuard config file
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
  vpnEnabled = cfg.enable && cfg.qbittorrent.enable && cfg.qbittorrent.vpn.enable;

  # VPN namespace name (limited to 7 characters by VPN-Confinement)
  vpnNamespace = "qbittor"; # Max 7 chars, shortened from qbittorrent
  bittorrentPort = (cfg.qbittorrent.bittorrent or {}).port or 6881;

  # ProtonVPN NAT-PMP gateway IP (typically 10.2.0.1 for ProtonVPN WireGuard)
  # This can be verified by running: ip route | grep default inside the namespace
  protonvpnGateway = "10.2.0.1";

  # Script to run natpmpc inside VPN namespace
  portForwardScript = pkgs.writeShellScript "protonvpn-port-forward-ns" ''
    set -euo pipefail

    # Wait for gateway to be reachable (check by trying natpmpc)
    # If gateway isn't ready, natpmpc will fail and service will restart

    # Run natpmpc loop inside namespace
    # This continuously forwards ports from ProtonVPN gateway
    # Note: ProtonVPN assigns a random public port, but forwards to our private port (${toString bittorrentPort})
    # qBittorrent should use its NAT-PMP feature to automatically detect and use the forwarded port
    while true; do
      date
      # Forward UDP port (ProtonVPN will assign a public port, forwards to our private port)
      ${pkgs.libnatpmp}/bin/natpmpc -a ${toString bittorrentPort} 0 udp 60 -g ${protonvpnGateway} || {
        echo "ERROR: UDP port forwarding failed" >&2
        exit 1
      }
      # Forward TCP port
      ${pkgs.libnatpmp}/bin/natpmpc -a ${toString bittorrentPort} 0 tcp 60 -g ${protonvpnGateway} || {
        echo "ERROR: TCP port forwarding failed" >&2
        exit 1
      }
      sleep 45
    done
  '';
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

    # ProtonVPN port forwarding service using NAT-PMP
    # This forwards ports from ProtonVPN's gateway to enable incoming connections
    # See: https://protonvpn.com/support/port-forwarding-manual-setup
    systemd.services.protonvpn-port-forwarding = {
      description = "ProtonVPN NAT-PMP Port Forwarding for qBittorrent";
      wantedBy = ["multi-user.target"];
      after = ["${vpnNamespace}.service"];
      wants = ["${vpnNamespace}.service"];

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "10s";

        # Wait for VPN namespace to exist
        ExecStartPre = pkgs.writeShellScript "check-vpn-namespace" ''
          # Wait for namespace to exist
          for i in {1..30}; do
            if ${pkgs.iproute2}/bin/ip netns list | grep -q "^${vpnNamespace} "; then
              exit 0
            fi
            sleep 1
          done
          echo "ERROR: VPN namespace ${vpnNamespace} not found" >&2
          exit 1
        '';

        # Run natpmpc inside the VPN namespace
        # Format: natpmpc -a <private_port> <public_port> <protocol> <lifetime> -g <gateway>
        # Using 0 for public_port means "any available port" (ProtonVPN will assign)
        # Lifetime of 60 seconds, renew every 45 seconds (as per ProtonVPN docs)
        ExecStart = "${pkgs.iproute2}/bin/ip netns exec ${vpnNamespace} ${portForwardScript}";

        # Security: Need NET_ADMIN to use network namespaces
        CapabilityBoundingSet = "CAP_NET_ADMIN";
        AmbientCapabilities = "CAP_NET_ADMIN";
      };
    };
  };
}
