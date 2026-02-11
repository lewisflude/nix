# ProtonVPN Port Forwarding Module
# Automatic NAT-PMP port forwarding with qBittorrent API integration
{ config, ... }:
{
  flake.modules.nixos.protonvpnPortforward =
    { pkgs, ... }:
    let
      namespace = "qbt";
      gateway = "10.2.0.1";
      renewInterval = "45s";
      leaseDuration = 60;
      qbtWebUIPort = 8080; # Internal port within namespace

      # Port forwarding script with correct NAT-PMP commands
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
          pkgs.inetutils
        ];
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          NAMESPACE="''${NAMESPACE:-qbt}"
          VPN_GATEWAY="''${VPN_GATEWAY:-10.2.0.1}"
          LEASE_DURATION="${toString leaseDuration}"
          STATE_FILE="/var/lib/protonvpn-portforward.state"
          QBT_HOST="127.0.0.1:${toString qbtWebUIPort}"
          LOG_PREFIX="[ProtonVPN-PortForward]"

          log_info() { echo "$LOG_PREFIX INFO: $*" >&2; }
          log_error() { echo "$LOG_PREFIX ERROR: $*" >&2; }
          log_success() { echo "$LOG_PREFIX SUCCESS: $*" >&2; }

          # Check if VPN namespace exists
          if ! ip netns list | grep -q "^$NAMESPACE"; then
            log_info "VPN namespace '$NAMESPACE' not found - VPN not connected, skipping"
            exit 0
          fi

          # Check if WireGuard interface is up in the namespace
          if ! ip netns exec "$NAMESPACE" ip link show "${namespace}0" 2>/dev/null | grep -q "state UP\|state UNKNOWN"; then
            log_info "WireGuard interface ${namespace}0 not up in namespace - VPN not connected, skipping"
            exit 0
          fi

          log_info "=== ProtonVPN NAT-PMP Port Forwarding ==="

          # Request BOTH UDP and TCP port mappings (required per ProtonVPN docs)
          log_info "Requesting UDP port mapping..."
          UDP_OUTPUT=$(ip netns exec "$NAMESPACE" natpmpc -a 1 0 udp "$LEASE_DURATION" -g "$VPN_GATEWAY" 2>&1) || true

          log_info "Requesting TCP port mapping..."
          TCP_OUTPUT=$(ip netns exec "$NAMESPACE" natpmpc -a 1 0 tcp "$LEASE_DURATION" -g "$VPN_GATEWAY" 2>&1) || true

          # Extract ports - ProtonVPN should assign the same port for both
          UDP_PORT=0
          TCP_PORT=0

          if echo "$UDP_OUTPUT" | grep -q "Mapped public port"; then
            UDP_PORT=$(echo "$UDP_OUTPUT" | grep -oP 'Mapped public port \K[0-9]+' || echo "0")
          fi

          if echo "$TCP_OUTPUT" | grep -q "Mapped public port"; then
            TCP_PORT=$(echo "$TCP_OUTPUT" | grep -oP 'Mapped public port \K[0-9]+' || echo "0")
          fi

          # Verify both protocols got the same port
          if [[ "$UDP_PORT" -gt 0 ]] && [[ "$TCP_PORT" -gt 0 ]]; then
            if [[ "$UDP_PORT" == "$TCP_PORT" ]]; then
              PUBLIC_PORT="$TCP_PORT"
              log_success "ProtonVPN assigned port: $PUBLIC_PORT (UDP+TCP)"
            else
              log_error "Port mismatch: UDP=$UDP_PORT, TCP=$TCP_PORT"
              exit 1
            fi
          else
            log_error "Failed to get port from NAT-PMP"
            log_error "UDP output: $UDP_OUTPUT"
            log_error "TCP output: $TCP_OUTPUT"
            exit 1
          fi

          # Get current qBittorrent port (localhost auth bypass enabled)
          log_info "Connecting to qBittorrent WebUI at http://$QBT_HOST..."
          PREFS=$(ip netns exec "$NAMESPACE" curl -s -m 10 \
            "http://$QBT_HOST/api/v2/app/preferences" 2>&1 || echo "{}")
          CURRENT_PORT=$(echo "$PREFS" | grep -oP '"listen_port":\K[0-9]+' || echo "0")

          log_info "Current qBittorrent port: $CURRENT_PORT"
          log_info "ProtonVPN assigned port: $PUBLIC_PORT"

          # Update qBittorrent port if needed
          if [[ "$CURRENT_PORT" == "$PUBLIC_PORT" ]]; then
            log_info "qBittorrent port already correct ($PUBLIC_PORT) - no update needed"
          else
            log_info "Updating qBittorrent port from $CURRENT_PORT to $PUBLIC_PORT..."

            # Update port AND interface binding
            UPDATE_RESPONSE=$(ip netns exec "$NAMESPACE" curl -s -m 10 -X POST \
              "http://$QBT_HOST/api/v2/app/setPreferences" \
              --data "json={\"listen_port\": $PUBLIC_PORT, \"current_interface_name\": \"${namespace}0\", \"current_interface_address\": \"10.2.0.2\"}" \
              2>&1 || echo "ERROR")

            if [[ -z "$UPDATE_RESPONSE" ]] || [[ "$UPDATE_RESPONSE" == "Ok." ]]; then
              log_success "qBittorrent port updated to $PUBLIC_PORT"
            else
              log_error "Failed to update port: $UPDATE_RESPONSE"
            fi

            # Verify qBittorrent is listening on new port
            sleep 2
            if ip netns exec "$NAMESPACE" ss -tuln 2>/dev/null | grep -q ":$PUBLIC_PORT "; then
              log_success "Verified: qBittorrent listening on port $PUBLIC_PORT"
            else
              log_info "qBittorrent may still be binding to port $PUBLIC_PORT"
            fi
          fi

          # Save state
          cat > "$STATE_FILE" << EOF
          # ProtonVPN Port Forwarding State
          # Last updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
          PUBLIC_PORT=$PUBLIC_PORT
          NAMESPACE=$NAMESPACE
          VPN_GATEWAY=$VPN_GATEWAY
          EOF
          chmod 644 "$STATE_FILE"

          log_success "=== Port Forwarding Complete: $PUBLIC_PORT ==="
          echo "$PUBLIC_PORT"
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
      environment.systemPackages = [
        pkgs.libnatpmp
        portforwardScript
      ];

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
          ReadWritePaths = [
            "/var/lib"
            "/tmp"
          ];
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
