# ProtonVPN Port Forwarding Module
# Long-running NAT-PMP port forwarding with qBittorrent API integration
# Runs inside VPN namespace via vpnConfinement with 30s renewal loop
_: {
  flake.modules.nixos.protonvpnPortforward =
    { pkgs, ... }:
    let
      namespace = "qbt";
      gateway = "10.2.0.1";
      leaseDuration = 60;
      renewInterval = 30;
      qbtWebUIPort = 8080;

      portforwardScript = pkgs.writeShellApplication {
        name = "protonvpn-portforward";
        runtimeInputs = [
          pkgs.libnatpmp
          pkgs.iproute2
          pkgs.gnugrep
          pkgs.coreutils
          pkgs.curl
          pkgs.iptables
        ];
        text = ''
          VPN_GATEWAY="''${VPN_GATEWAY:-${gateway}}"
          LEASE_DURATION="${toString leaseDuration}"
          QBT_HOST="127.0.0.1:${toString qbtWebUIPort}"
          IFACE="${namespace}0"
          LOG_PREFIX="[ProtonVPN-PortForward]"
          PREV_PORT=""

          log_info()    { echo "$LOG_PREFIX INFO: $*" >&2; }
          log_error()   { echo "$LOG_PREFIX ERROR: $*" >&2; }
          log_success() { echo "$LOG_PREFIX SUCCESS: $*" >&2; }

          cleanup() {
            log_info "Shutting down, cleaning up firewall rules..."
            if [[ -n "$PREV_PORT" ]]; then
              iptables -D INPUT -p tcp --dport "$PREV_PORT" -i "$IFACE" -j ACCEPT 2>/dev/null || true
              iptables -D INPUT -p udp --dport "$PREV_PORT" -i "$IFACE" -j ACCEPT 2>/dev/null || true
              log_info "Removed firewall rules for port $PREV_PORT"
            fi
          }
          trap cleanup EXIT

          # Wait for WireGuard interface
          log_info "Waiting for WireGuard interface $IFACE..."
          for i in $(seq 1 30); do
            if ip link show "$IFACE" 2>/dev/null | grep -qE "state (UP|UNKNOWN)"; then
              log_info "Interface $IFACE is up"
              break
            fi
            if [[ "$i" -eq 30 ]]; then
              log_error "Timed out waiting for $IFACE"
              exit 1
            fi
            sleep 2
          done

          log_info "Starting NAT-PMP renewal loop (every ${toString renewInterval}s, lease ${toString leaseDuration}s)"

          while true; do
            # Request both UDP and TCP mappings (required by ProtonVPN)
            UDP_OUTPUT=$(natpmpc -a 1 0 udp "$LEASE_DURATION" -g "$VPN_GATEWAY" 2>&1) || true
            TCP_OUTPUT=$(natpmpc -a 1 0 tcp "$LEASE_DURATION" -g "$VPN_GATEWAY" 2>&1) || true

            UDP_PORT=0
            TCP_PORT=0

            if echo "$UDP_OUTPUT" | grep -q "Mapped public port"; then
              UDP_PORT=$(echo "$UDP_OUTPUT" | grep -oP 'Mapped public port \K[0-9]+' || echo "0")
            fi
            if echo "$TCP_OUTPUT" | grep -q "Mapped public port"; then
              TCP_PORT=$(echo "$TCP_OUTPUT" | grep -oP 'Mapped public port \K[0-9]+' || echo "0")
            fi

            if [[ "$UDP_PORT" -gt 0 ]] && [[ "$TCP_PORT" -gt 0 ]] && [[ "$UDP_PORT" == "$TCP_PORT" ]]; then
              PUBLIC_PORT="$TCP_PORT"
              log_success "NAT-PMP assigned port: $PUBLIC_PORT (UDP+TCP)"
            else
              log_error "NAT-PMP failed or port mismatch (UDP=$UDP_PORT TCP=$TCP_PORT)"
              log_error "UDP: $UDP_OUTPUT"
              log_error "TCP: $TCP_OUTPUT"
              sleep "${toString renewInterval}"
              continue
            fi

            # Update firewall: add new rules first, then remove old (zero-downtime)
            if [[ "$PUBLIC_PORT" != "$PREV_PORT" ]]; then
              for proto in tcp udp; do
                if ! iptables -C INPUT -p "$proto" --dport "$PUBLIC_PORT" -i "$IFACE" -j ACCEPT 2>/dev/null; then
                  iptables -I INPUT -p "$proto" --dport "$PUBLIC_PORT" -i "$IFACE" -j ACCEPT
                  log_info "Added $proto firewall rule for port $PUBLIC_PORT"
                fi
              done

              if [[ -n "$PREV_PORT" ]] && [[ "$PREV_PORT" != "$PUBLIC_PORT" ]]; then
                for proto in tcp udp; do
                  iptables -D INPUT -p "$proto" --dport "$PREV_PORT" -i "$IFACE" -j ACCEPT 2>/dev/null || true
                done
                log_info "Removed old firewall rules for port $PREV_PORT"
              fi

              PREV_PORT="$PUBLIC_PORT"
            fi

            # Update qBittorrent port if needed
            PREFS=$(curl -s -m 10 "http://$QBT_HOST/api/v2/app/preferences" 2>/dev/null || echo "{}")
            CURRENT_PORT=$(echo "$PREFS" | grep -oP '"listen_port":\K[0-9]+' || echo "0")

            if [[ "$CURRENT_PORT" != "$PUBLIC_PORT" ]]; then
              log_info "Updating qBittorrent port from $CURRENT_PORT to $PUBLIC_PORT..."
              curl -s -m 10 -X POST \
                "http://$QBT_HOST/api/v2/app/setPreferences" \
                --data "json={\"listen_port\": $PUBLIC_PORT, \"current_interface_name\": \"$IFACE\", \"current_interface_address\": \"10.2.0.2\"}" \
                2>/dev/null || log_error "Failed to update qBittorrent port"
            fi

            sleep "${toString renewInterval}"
          done
        '';
      };
    in
    {
      environment.systemPackages = [
        pkgs.libnatpmp
        portforwardScript
      ];

      systemd.services.protonvpn-portforward = {
        description = "ProtonVPN NAT-PMP Port Forwarding (loop-based)";
        after = [
          "network-online.target"
          "${namespace}.service"
          "qbittorrent.service"
        ];
        wants = [
          "network-online.target"
          "${namespace}.service"
        ];
        wantedBy = [ "multi-user.target" ];

        vpnConfinement = {
          enable = true;
          vpnNamespace = namespace;
        };

        serviceConfig = {
          Type = "simple";
          ExecStart = "${portforwardScript}/bin/protonvpn-portforward";
          Restart = "on-failure";
          RestartSec = "10s";
          Environment = [ "VPN_GATEWAY=${gateway}" ];
          PrivateTmp = true;
          NoNewPrivileges = false;
          ProtectHome = true;
        };
      };
    };
}
