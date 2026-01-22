{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.host.services.mediaManagement;
  qbittorrentCfg = cfg.qbittorrent or { };
  vpnCfg = qbittorrentCfg.vpn or { };

  healthCheckCfg = qbittorrentCfg.vpn.healthCheck or { };
in
{
  options.host.services.mediaManagement.qbittorrent.vpn.healthCheck = {
    enable = mkEnableOption "qBittorrent VPN health monitoring" // {
      default = true;
    };

    checkInterval = mkOption {
      type = types.str;
      default = "2min";
      description = "How often to check VPN binding health";
    };

    startDelay = mkOption {
      type = types.str;
      default = "5min";
      description = "How long to wait after boot before starting health checks";
    };

    restartOnFailure = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically restart qBittorrent if VPN binding check fails";
    };
  };

  config =
    mkIf (cfg.enable && qbittorrentCfg.enable && vpnCfg.enable && (healthCheckCfg.enable or true))
      {
        systemd.timers.qbittorrent-vpn-health = {
          description = "qBittorrent VPN Health Check Timer";
          wantedBy = [ "timers.target" ];
          after = [ "qbittorrent.service" ];

          timerConfig = {
            OnBootSec = healthCheckCfg.startDelay;
            OnUnitActiveSec = healthCheckCfg.checkInterval;
            Persistent = true;
            RandomizedDelaySec = "30s"; # Add jitter to prevent thundering herd
            Unit = "qbittorrent-vpn-health.service";
          };
        };

        systemd.services.qbittorrent-vpn-health = {
          description = "Verify qBittorrent VPN Binding";
          after = [ "qbittorrent.service" ];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellScript "check-qbt-vpn" ''
              #!/bin/sh
              set -euo pipefail

              NAMESPACE="${vpnCfg.namespace}"
              VPN_INTERFACE="${vpnCfg.interface or "proton0"}"

              echo "Checking qBittorrent VPN binding..."

              # Check if qBittorrent is running
              if ! ${pkgs.systemd}/bin/systemctl is-active --quiet qbittorrent.service; then
                echo "INFO: qBittorrent is not running, skipping check"
                exit 0
              fi

              # Check if VPN namespace exists
              if ! ${pkgs.iproute2}/bin/ip netns list | grep -q "^${vpnCfg.namespace}"; then
                echo "ERROR: VPN namespace '${vpnCfg.namespace}' does not exist"
                ${
                  if healthCheckCfg.restartOnFailure then
                    ''
                      echo "Restarting qBittorrent service..."
                      ${pkgs.systemd}/bin/systemctl restart qbittorrent.service
                    ''
                  else
                    "exit 1"
                }
              fi

              # Check if VPN interface is up in the namespace
              if ! ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ip link show "$VPN_INTERFACE" 2>/dev/null | grep -q "state UP"; then
                echo "ERROR: VPN interface '$VPN_INTERFACE' is not up in namespace '$NAMESPACE'"
                ${
                  if healthCheckCfg.restartOnFailure then
                    ''
                      echo "Restarting qBittorrent service..."
                      ${pkgs.systemd}/bin/systemctl restart qbittorrent.service
                    ''
                  else
                    "exit 1"
                }
              fi

              # Check if we can get external IP through VPN
              VPN_IP=$(${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.curl}/bin/curl -s --max-time 10 https://api.ipify.org || echo "")
              if [ -z "$VPN_IP" ]; then
                echo "ERROR: Cannot determine external IP through VPN namespace"
                ${
                  if healthCheckCfg.restartOnFailure then
                    ''
                      echo "Restarting qBittorrent service..."
                      ${pkgs.systemd}/bin/systemctl restart qbittorrent.service
                    ''
                  else
                    "exit 1"
                }
              fi

              echo "✓ VPN health check passed"
              echo "  Namespace: $NAMESPACE"
              echo "  Interface: $VPN_INTERFACE"
              echo "  External IP: $VPN_IP"
            ''}";

            StandardOutput = "journal";
            StandardError = "journal";
            SyslogIdentifier = "qbittorrent-vpn-health";

            # Timeout settings
            TimeoutStartSec = "30s";

            # Basic security
            PrivateTmp = true;
            NoNewPrivileges = false; # Needed for ip netns exec
            ProtectSystem = "strict";
            ProtectHome = true;

            # Network
            PrivateNetwork = false; # Need access to namespaces
          };

          # Notify on failure
          unitConfig.OnFailure = "notify-failure@%n.service";
        };
      };
}
