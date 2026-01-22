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
  portForwardingCfg = qbittorrentCfg.vpn.portForwarding or { };

  monitorCfg = portForwardingCfg.monitoring or { };
in
{
  options.host.services.mediaManagement.qbittorrent.vpn.portForwarding.monitoring = {
    enable = mkEnableOption "ProtonVPN port forwarding freshness monitoring" // {
      default = true;
    };

    checkInterval = mkOption {
      type = types.str;
      default = "5min";
      description = "How often to check if port forward state is fresh";
    };

    maxAge = mkOption {
      type = types.int;
      default = 300; # 5 minutes in seconds
      description = "Maximum age (in seconds) before port forward is considered stale";
    };

    restartTimerOnStale = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically restart the port forwarding timer if state is stale";
    };
  };

  config =
    mkIf
      (
        cfg.enable
        && qbittorrentCfg.enable
        && vpnCfg.enable
        && (portForwardingCfg.enable or true)
        && (monitorCfg.enable or true)
      )
      {
        systemd.timers.protonvpn-portforward-monitor = {
          description = "ProtonVPN Port Forward Freshness Monitor";
          wantedBy = [ "timers.target" ];
          after = [ "protonvpn-portforward.timer" ];

          timerConfig = {
            OnBootSec = "10min"; # Wait for initial port forward to establish
            OnUnitActiveSec = monitorCfg.checkInterval;
            Persistent = true;
            AccuracySec = "1min"; # Allow some jitter
            Unit = "protonvpn-portforward-monitor.service";
          };
        };

        systemd.services.protonvpn-portforward-monitor = {
          description = "Check ProtonVPN Port Forward Freshness";
          after = [ "protonvpn-portforward.service" ];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellScript "check-portforward-freshness" ''
              #!/bin/sh
              set -euo pipefail

              STATE_FILE="/var/lib/protonvpn-portforward.state"
              MAX_AGE=${toString monitorCfg.maxAge}

              echo "Checking ProtonVPN port forward freshness..."

              # Check if state file exists
              if [ ! -f "$STATE_FILE" ]; then
                echo "WARN: No port forward state file found at $STATE_FILE"
                echo "This is normal on first boot - timer should create it soon"
                exit 0
              fi

              # Get file modification time
              LAST_UPDATE=$(${pkgs.coreutils}/bin/stat -c %Y "$STATE_FILE")
              NOW=$(${pkgs.coreutils}/bin/date +%s)
              AGE=$((NOW - LAST_UPDATE))

              # Check if port forward is stale
              if [ $AGE -gt $MAX_AGE ]; then
                echo "ERROR: Port forward state is stale (''${AGE}s old, max: ''${MAX_AGE}s)"
                
                # Read current port from state file
                if [ -f "$STATE_FILE" ]; then
                  CURRENT_PORT=$(${pkgs.gnugrep}/bin/grep "PUBLIC_PORT=" "$STATE_FILE" | ${pkgs.coreutils}/bin/cut -d= -f2 || echo "unknown")
                  echo "Current port: $CURRENT_PORT"
                fi

                ${
                  if monitorCfg.restartTimerOnStale then
                    ''
                      echo "Restarting port forwarding timer to renew lease..."
                      ${pkgs.systemd}/bin/systemctl restart protonvpn-portforward.timer
                      echo "Timer restarted - port forward will renew shortly"
                    ''
                  else
                    "exit 1"
                }
              else
                echo "✓ Port forward is fresh (''${AGE}s old)"
                
                # Read and display current port info
                if [ -f "$STATE_FILE" ]; then
                  CURRENT_PORT=$(${pkgs.gnugrep}/bin/grep "PUBLIC_PORT=" "$STATE_FILE" | ${pkgs.coreutils}/bin/cut -d= -f2 || echo "unknown")
                  PRIVATE_PORT=$(${pkgs.gnugrep}/bin/grep "PRIVATE_PORT=" "$STATE_FILE" | ${pkgs.coreutils}/bin/cut -d= -f2 || echo "unknown")
                  echo "  Public port: $CURRENT_PORT"
                  echo "  Private port: $PRIVATE_PORT"
                fi
              fi
            ''}";

            StandardOutput = "journal";
            StandardError = "journal";
            SyslogIdentifier = "protonvpn-portforward-monitor";

            # Timeout
            TimeoutStartSec = "30s";

            # Security
            PrivateTmp = true;
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadOnlyPaths = [ "/var/lib" ];

            # Network
            PrivateNetwork = false;
          };

          # Notify on failure
          unitConfig.OnFailure = "notify-failure@%n.service";
        };
      };
}
