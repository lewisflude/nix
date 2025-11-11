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
  cfg = config.services.protonvpnPortForwarding;
in
{
  options.services.protonvpnPortForwarding = {
    enable = mkEnableOption "ProtonVPN NAT-PMP port forwarding";

    vpnInterface = mkOption {
      type = types.str;
      default = "qbittor0";
      description = "VPN WireGuard interface name";
    };

    vpnGateway = mkOption {
      type = types.str;
      default = "10.2.0.1";
      description = "VPN gateway IP address (ProtonVPN DNS/gateway)";
    };

    internalPort = mkOption {
      type = types.port;
      default = 6881;
      description = "Internal port to forward (the port your application listens on)";
    };

    leaseTime = mkOption {
      type = types.int;
      default = 60;
      description = "NAT-PMP lease time in seconds (should be 60 for ProtonVPN)";
    };

    renewInterval = mkOption {
      type = types.int;
      default = 45;
      description = "How often to renew the port mapping in seconds (should be less than leaseTime)";
    };

    updateQBittorrent = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically update qBittorrent port when a new port is assigned";
    };

    qbittorrent = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            webuiUrl = mkOption {
              type = types.str;
              default = "http://192.168.15.1:8080";
              description = "qBittorrent WebUI URL";
            };
            username = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "qBittorrent WebUI username";
            };
            password = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "qBittorrent WebUI password";
            };
          };
        }
      );
      default = null;
      description = "qBittorrent configuration for automatic port updates";
    };
  };

  config = mkIf cfg.enable {
    # Ensure required packages are available
    environment.systemPackages = [
      pkgs.libnatpmp
    ]
    ++ lib.optionals cfg.updateQBittorrent [
      pkgs.curl
      pkgs.jq
    ];

    # Script that runs the NAT-PMP loop
    systemd.services.protonvpn-port-forwarding = {
      description = "ProtonVPN NAT-PMP Port Forwarding";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "systemd-networkd.service"
      ];
      # Wait for network and WireGuard interface to be ready
      requires = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10s";
        # Ensure all required tools are in PATH
        Environment = "PATH=${
          lib.makeBinPath [
            pkgs.iproute2
            pkgs.libnatpmp
            pkgs.gnugrep
            pkgs.coreutils
            pkgs.bash
          ]
        }";
        ExecStart =
          let
            script = pkgs.writeShellScript "protonvpn-natpmp-loop" ''
              set -euo pipefail

              VPN_INTERFACE="${cfg.vpnInterface}"
              VPN_GATEWAY="${cfg.vpnGateway}"
              INTERNAL_PORT="${toString cfg.internalPort}"
              LEASE_TIME="${toString cfg.leaseTime}"
              RENEW_INTERVAL="${toString cfg.renewInterval}"

              # Wait for VPN interface to exist
              echo "Waiting for VPN interface '$VPN_INTERFACE' to be available..."
              for i in {1..30}; do
                if ${pkgs.iproute2}/bin/ip link show "$VPN_INTERFACE" >/dev/null 2>&1; then
                  echo "VPN interface '$VPN_INTERFACE' found"
                  break
                fi
                if [ $i -eq 30 ]; then
                  echo "ERROR: VPN interface '$VPN_INTERFACE' not found after 30 attempts"
                  exit 1
                fi
                sleep 1
              done

              # Wait for VPN interface to be up
              echo "Waiting for VPN interface to be up..."
              for i in {1..30}; do
                if ${pkgs.iproute2}/bin/ip link show "$VPN_INTERFACE" | grep -q "UP"; then
                  echo "VPN interface is up"
                  break
                fi
                if [ $i -eq 30 ]; then
                  echo "ERROR: VPN interface not up after 30 attempts"
                  exit 1
                fi
                sleep 1
              done

              # Function to update qBittorrent port (if enabled)
              update_qbittorrent() {
                local port=$1
                ${
                  if cfg.updateQBittorrent && cfg.qbittorrent != null then
                    ''
                      local webui_url="${cfg.qbittorrent.webuiUrl}"
                      local username="${if cfg.qbittorrent.username != null then cfg.qbittorrent.username else ""}"
                      local password="${if cfg.qbittorrent.password != null then cfg.qbittorrent.password else ""}"

                      # Try to get password from SOPS if not provided
                      if [ -z "$password" ] && command -v sops >/dev/null 2>&1; then
                        # Try reading from SOPS secrets file
                        if [ -f "${toString config.sops.defaultSopsFile}" ]; then
                          password=$(sops -d "${toString config.sops.defaultSopsFile}" 2>/dev/null | \
                            grep -A 5 'qbittorrent:' | grep 'password:' | awk '{print $2}' | tr -d '"' || echo "")
                        fi
                      fi

                      if [ -z "$password" ]; then
                        echo "Warning: Cannot update qBittorrent - password not available"
                        return
                      fi

                      # Authenticate and update port
                      cookie_file=$(mktemp)
                      auth_response=$(${pkgs.curl}/bin/curl -s -c "$cookie_file" -X POST "$webui_url/api/v2/auth/login" \
                        -d "username=$username&password=$password" || echo "")

                      if [ "$auth_response" != "Ok." ]; then
                        echo "Warning: Failed to authenticate with qBittorrent WebUI"
                        rm -f "$cookie_file"
                        return
                      fi

                      # Get current preferences
                      prefs=$(${pkgs.curl}/bin/curl -s -b "$cookie_file" "$webui_url/api/v2/app/preferences" || echo "{}")
                      current_port=$(echo "$prefs" | ${pkgs.jq}/bin/jq -r '.listen_port // empty' || echo "")

                      if [ "$current_port" = "$port" ]; then
                        echo "qBittorrent already using port $port"
                        rm -f "$cookie_file"
                        return
                      fi

                      # Update port
                      updated_prefs=$(echo "$prefs" | ${pkgs.jq}/bin/jq ".listen_port = $port")
                      update_response=$(${pkgs.curl}/bin/curl -s -b "$cookie_file" -X POST \
                        "$webui_url/api/v2/app/setPreferences" \
                        -H "Content-Type: application/json" \
                        -d "$updated_prefs" || echo "")

                      if [ "$update_response" = "Ok." ]; then
                        echo "? Updated qBittorrent port to $port"
                      else
                        echo "Warning: Failed to update qBittorrent port"
                      fi

                      rm -f "$cookie_file"
                    ''
                  else
                    ''
                      # qBittorrent update disabled or not configured
                      return
                    ''
                }
              }

              # Main loop
              echo "Starting NAT-PMP port forwarding loop..."
              echo "Gateway: $VPN_GATEWAY"
              echo "Internal port: $INTERNAL_PORT"
              echo "Lease time: $LEASE_TIME seconds"
              echo "Renew interval: $RENEW_INTERVAL seconds"
              echo ""

              LAST_PORT=""

              while true; do
                date

                # Request UDP port mapping
                # Request any external port (0) -> internal port 6881
                # Note: natpmpc -a format is: <public port> <private port> <protocol> [lifetime]
                UDP_OUTPUT=$(${pkgs.libnatpmp}/bin/natpmpc \
                  -g "$VPN_GATEWAY" \
                  -a 0 "$INTERNAL_PORT" udp "$LEASE_TIME" 2>&1 || echo "")

                # Request TCP port mapping
                # Request any external port (0) -> internal port 6881
                # Note: natpmpc -a format is: <public port> <private port> <protocol> [lifetime]
                TCP_OUTPUT=$(${pkgs.libnatpmp}/bin/natpmpc \
                  -g "$VPN_GATEWAY" \
                  -a 0 "$INTERNAL_PORT" tcp "$LEASE_TIME" 2>&1 || echo "")

                # Extract external port from output
                # NAT-PMP output format: "Mapped public port 64996 protocol TCP to local port 6881 lifetime 60"
                EXTERNAL_PORT=$(echo "$UDP_OUTPUT" | grep -oP 'Mapped public port \K[0-9]+' || echo "")

                if [ -z "$EXTERNAL_PORT" ] || [ "$EXTERNAL_PORT" = "0" ]; then
                  EXTERNAL_PORT=$(echo "$TCP_OUTPUT" | grep -oP 'Mapped public port \K[0-9]+' || echo "")
                fi

                if [ -n "$EXTERNAL_PORT" ] && [ "$EXTERNAL_PORT" != "0" ]; then
                  if [ "$EXTERNAL_PORT" != "$LAST_PORT" ]; then
                    echo "? Port forwarding active: External port $EXTERNAL_PORT -> Internal port $INTERNAL_PORT"
                    LAST_PORT="$EXTERNAL_PORT"

                    # Update qBittorrent if enabled
                    update_qbittorrent "$EXTERNAL_PORT"
                  else
                    echo "? Port forwarding renewed: External port $EXTERNAL_PORT -> Internal port $INTERNAL_PORT"
                  fi
                else
                  echo "? ERROR: Failed to get external port from NAT-PMP"
                  echo "UDP output: $UDP_OUTPUT"
                  echo "TCP output: $TCP_OUTPUT"
                  echo "? Port forwarding may not be working correctly"
                fi

                sleep "$RENEW_INTERVAL"
              done
            '';
          in
          "${script}";
        # Run NAT-PMP commands directly on the main network namespace
      };
    };
  };
}
