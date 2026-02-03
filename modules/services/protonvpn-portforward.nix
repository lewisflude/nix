# ProtonVPN Port Forwarding Module
# Automatic NAT-PMP port forwarding with qBittorrent API integration
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.protonvpnPortforward = { lib, pkgs, ... }:
  let
    namespace = "qbt";
    gateway = "10.2.0.1";
    renewInterval = "45s";

    # Port forwarding script
    portforwardScript = pkgs.writeShellApplication {
      name = "protonvpn-portforward";
      runtimeInputs = [
        pkgs.libnatpmp
        pkgs.iproute2
        pkgs.systemd
        pkgs.gnugrep
        pkgs.gnused
        pkgs.coreutils
        pkgs.curl
        pkgs.iptables
      ];
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        NAMESPACE="''${NAMESPACE:-qbt}"
        VPN_GATEWAY="''${VPN_GATEWAY:-10.2.0.1}"
        STATE_FILE="/var/lib/protonvpn-portforward.state"
        QBT_API="http://127.0.0.1:${toString constants.ports.services.qbittorrent}/api/v2"

        # Check if VPN namespace exists
        if ! ip netns list | grep -q "^$NAMESPACE"; then
          echo "VPN namespace '$NAMESPACE' not found - VPN not connected, skipping"
          exit 0
        fi

        # Check if VPN gateway is reachable within the namespace
        if ! ip netns exec "$NAMESPACE" ip route | grep -q "$VPN_GATEWAY"; then
          echo "VPN gateway $VPN_GATEWAY not reachable in namespace - VPN not connected, skipping"
          exit 0
        fi

        echo "Requesting port forward from ProtonVPN gateway $VPN_GATEWAY..."

        # Request port via NAT-PMP in VPN namespace
        RESULT=$(ip netns exec "$NAMESPACE" natpmpc -g "$VPN_GATEWAY" 2>&1) || true

        # Extract the assigned port
        PUBLIC_PORT=$(echo "$RESULT" | grep -oP 'Mapped public port \K[0-9]+' || echo "")

        if [ -z "$PUBLIC_PORT" ]; then
          echo "Failed to get port from NAT-PMP - VPN may not support port forwarding"
          exit 0
        fi

        echo "Got port: $PUBLIC_PORT"

        # Save state
        echo "PUBLIC_PORT=$PUBLIC_PORT" > "$STATE_FILE"
        echo "TIMESTAMP=$(date +%s)" >> "$STATE_FILE"

        # Update qBittorrent listen port
        echo "Updating qBittorrent listen port..."
        curl -s -X POST "$QBT_API/app/setPreferences" \
          -d "json={\"listen_port\":$PUBLIC_PORT}" || true

        echo "Port forwarding configured: $PUBLIC_PORT"
      '';
    };

    # Firewall update script
    firewallScript = pkgs.writeShellScript "update-qbt-firewall" ''
      #!/usr/bin/env bash
      set -euo pipefail

      NAMESPACE="''${1:-qbt}"
      NEW_PORT="''${2:-0}"

      if [[ "$NEW_PORT" -eq 0 ]]; then
        echo "Error: Port not provided"
        exit 1
      fi

      echo "Updating firewall for port $NEW_PORT in namespace $NAMESPACE..."

      for protocol in tcp udp; do
        if ! ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/iptables -C INPUT -p "$protocol" --dport "$NEW_PORT" -i "$NAMESPACE"0 -j ACCEPT 2>/dev/null; then
          ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/iptables -I INPUT -p "$protocol" --dport "$NEW_PORT" -i "$NAMESPACE"0 -j ACCEPT
          echo "Added IPv4 $protocol rule for port $NEW_PORT"
        fi
      done

      echo "Firewall updated successfully for port $NEW_PORT"
    '';
  in
  {
    systemd.services.protonvpn-portforward = {
      description = "ProtonVPN NAT-PMP Port Forwarding with qBittorrent Integration";
      after = [
        "network-online.target"
        "${namespace}.service"
        "qbittorrent.service"
        "configure-qbt-routes.service"
      ];
      wants = [
        "network-online.target"
        "${namespace}.service"
      ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${portforwardScript}/bin/protonvpn-portforward";
        ExecStartPost = "${pkgs.bash}/bin/bash -c 'PORT=$(grep PUBLIC_PORT /var/lib/protonvpn-portforward.state 2>/dev/null | cut -d= -f2); [ -n \"$PORT\" ] && ${firewallScript} ${namespace} \"$PORT\" || echo \"No port to configure\"'";
        Environment = [
          "NAMESPACE=${namespace}"
          "VPN_GATEWAY=${gateway}"
        ];
        TimeoutStartSec = "60s";
        PrivateTmp = true;
        NoNewPrivileges = false;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib" ];
        PrivateNetwork = false;
      };
    };

    systemd.timers.protonvpn-portforward = {
      description = "Timer for ProtonVPN NAT-PMP Port Forwarding Renewal";
      wantedBy = [ "timers.target" ];
      after = [ "${namespace}.service" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = renewInterval;
        Unit = "protonvpn-portforward.service";
        Persistent = true;
        AccuracySec = "1min";
      };
    };
  };
}
