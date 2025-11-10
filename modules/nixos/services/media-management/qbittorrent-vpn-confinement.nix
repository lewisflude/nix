{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.services.mediaManagement;
  vpnEnabled = cfg.enable && cfg.qbittorrent.enable && cfg.qbittorrent.vpn.enable;

  vpnNamespace = "qbittor";
  bittorrentPort = (cfg.qbittorrent.bittorrent or { }).port or 6881;

  protonvpnGateway = "10.2.0.1";

  # Default MTU - can be overridden via WireGuard config
  defaultMTU = 1420;

  # Script to apply performance optimizations to VPN namespace
  vpnOptimizeScript = pkgs.writeShellScript "vpn-optimize-ns" ''
    set -euo pipefail

    namespace="${vpnNamespace}"
    interface="qbittor0"
    mtu="${toString defaultMTU}"

    # Wait for namespace to exist
    max_attempts=30
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
      if ${pkgs.iproute2}/bin/ip netns list | grep -q "^$namespace"; then
        break
      fi
      sleep 1
      attempt=$((attempt + 1))
    done

    if [ $attempt -eq $max_attempts ]; then
      echo "ERROR: Namespace $namespace not found after $max_attempts attempts" >&2
      exit 1
    fi

    # Wait for interface to exist
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
      if ${pkgs.iproute2}/bin/ip netns exec "$namespace" ${pkgs.iproute2}/bin/ip link show "$interface" >/dev/null 2>&1; then
        break
      fi
      sleep 1
      attempt=$((attempt + 1))
    done

    if [ $attempt -eq $max_attempts ]; then
      echo "ERROR: Interface $interface not found in namespace $namespace" >&2
      exit 1
    fi

    # Apply sysctl settings to namespace for optimal WireGuard performance
    echo "Applying performance optimizations to namespace $namespace..."

    # Network buffer optimizations (IPv4)
    ${pkgs.iproute2}/bin/ip netns exec "$namespace" ${pkgs.procps}/bin/sysctl -w net.core.rmem_max=16777216 || true
    ${pkgs.iproute2}/bin/ip netns exec "$namespace" ${pkgs.procps}/bin/sysctl -w net.core.wmem_max=16777216 || true

    # IPv4 TCP buffer sizes (min, default, max)
    ${pkgs.iproute2}/bin/ip netns exec "$namespace" ${pkgs.procps}/bin/sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216" || true
    ${pkgs.iproute2}/bin/ip netns exec "$namespace" ${pkgs.procps}/bin/sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216" || true

    # BBR congestion control (IPv4)
    ${pkgs.iproute2}/bin/ip netns exec "$namespace" ${pkgs.procps}/bin/sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null || true

    # Set MTU if different from target (may already be set in WireGuard config)
    current_mtu=$(${pkgs.iproute2}/bin/ip netns exec "$namespace" ${pkgs.iproute2}/bin/ip link show "$interface" 2>/dev/null | ${pkgs.gawk}/bin/awk '/mtu/ {print $5}' || echo "")
    if [ -n "$current_mtu" ] && [ "$current_mtu" != "$mtu" ]; then
      echo "Setting MTU to $mtu on $interface (current: $current_mtu)"
      ${pkgs.iproute2}/bin/ip netns exec "$namespace" ${pkgs.iproute2}/bin/ip link set "$interface" mtu "$mtu" 2>/dev/null || {
        echo "Note: MTU may already be set in WireGuard config (current: $current_mtu)" >&2
      }
    elif [ -z "$current_mtu" ]; then
      echo "Setting MTU to $mtu on $interface"
      ${pkgs.iproute2}/bin/ip netns exec "$namespace" ${pkgs.iproute2}/bin/ip link set "$interface" mtu "$mtu" 2>/dev/null || true
    else
      echo "MTU already set to $mtu on $interface"
    fi

    echo "Performance optimizations applied successfully"
  '';

  portForwardScript = pkgs.writeShellScript "protonvpn-port-forward-ns" ''
    set -euo pipefail




    ${pkgs.iproute2}/bin/ip route add ${protonvpnGateway}/32 dev qbittor0 2>/dev/null || true








    while true; do
      date

      ${pkgs.libnatpmp}/bin/natpmpc -a ${toString bittorrentPort} 0 udp 60 -g ${protonvpnGateway} || {
        echo "ERROR: UDP port forwarding failed" >&2
        exit 1
      }

      ${pkgs.libnatpmp}/bin/natpmpc -a ${toString bittorrentPort} 0 tcp 60 -g ${protonvpnGateway} || {
        echo "ERROR: TCP port forwarding failed" >&2
        exit 1
      }
      sleep 45
    done
  '';
in
{
  config = mkIf vpnEnabled {

    vpnNamespaces.${vpnNamespace} = {
      enable = true;

      wireguardConfigFile = config.sops.secrets."vpn-confinement-qbittorrent".path;
      accessibleFrom = [
        "127.0.0.1/32"
        "192.168.1.0/24"
        "192.168.0.0/24"
        "10.0.0.0/8"
      ];
      portMappings = [
        {

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

      openVPNPorts = [
        {
          port = bittorrentPort;
          protocol = "both";
        }
      ];
    };

    # Service to apply performance optimizations to VPN namespace
    systemd.services.qbittorrent-vpn-optimize = {
      description = "Apply WireGuard Performance Optimizations to qBittorrent VPN Namespace";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      # Script handles waiting for namespace and interface to be ready

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = vpnOptimizeScript;
      };
    };

    systemd.services.protonvpn-port-forwarding = {
      description = "ProtonVPN NAT-PMP Port Forwarding for qBittorrent";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "qbittorrent-vpn-optimize.service"
      ];
      wants = [ "qbittorrent-vpn-optimize.service" ];

      vpnConfinement = {
        enable = true;
        inherit vpnNamespace;
      };

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "10s";

        ExecStart = portForwardScript;
      };
    };
  };
}
