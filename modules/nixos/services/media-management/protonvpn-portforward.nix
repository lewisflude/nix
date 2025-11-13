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

  portforwardScript = pkgs.writeShellApplication {
    name = "protonvpn-portforward";
    runtimeInputs = with pkgs; [
      libnatpmp
      iproute2
      systemd
      gnugrep
      gnused
      coreutils
      curl
    ];
    text = builtins.readFile ../../../../scripts/protonvpn-natpmp-portforward.sh;
  };
in
{
  options.host.services.mediaManagement.qbittorrent.vpn.portForwarding = {
    enable = mkEnableOption "Automatic ProtonVPN port forwarding via NAT-PMP" // {
      default = true;
    };

    renewInterval = mkOption {
      type = types.str;
      default = "45min";
      description = "How often to renew the port forwarding lease (NAT-PMP leases expire after ~60min)";
    };

    namespace = mkOption {
      type = types.str;
      default = vpnCfg.namespace or "qbt";
      description = "VPN namespace name (inherited from VPN configuration)";
    };

    gateway = mkOption {
      type = types.str;
      default = "10.2.0.1";
      description = "ProtonVPN gateway IP address for NAT-PMP queries";
    };
  };

  config =
    mkIf
      (
        cfg.enable
        && qbittorrentCfg.enable
        && vpnCfg.enable
        && (qbittorrentCfg.vpn.portForwarding.enable or true)
      )
      {
        # Systemd service to update port forwarding
        # Note: This service is only triggered by the timer, not started directly on boot
        systemd.services.protonvpn-portforward = {
          description = "ProtonVPN NAT-PMP Port Forwarding for qBittorrent";
          after = [
            "network-online.target"
            "${vpnCfg.namespace}.service"
            "qbittorrent.service"
          ];
          wants = [
            "network-online.target"
            "${vpnCfg.namespace}.service"
          ];

          # Don't use 'requisite' - it prevents the service from being defined if dependency is missing
          # The script will check if namespace exists and fail gracefully

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${portforwardScript}/bin/protonvpn-portforward";

            # Environment
            Environment = [
              "NAMESPACE=${qbittorrentCfg.vpn.portForwarding.namespace}"
              "VPN_GATEWAY=${qbittorrentCfg.vpn.portForwarding.gateway}"
            ];

            # Timeout settings
            TimeoutStartSec = "60s";

            # Security
            PrivateTmp = true;
            NoNewPrivileges = false; # Needed for ip netns exec
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [
              "/var/lib/qBittorrent" # Need to update config
            ];

            # Network
            PrivateNetwork = false; # Need access to namespaces

            # Logging
            StandardOutput = "journal";
            StandardError = "journal";
          };
        };

        # Timer to run periodically
        systemd.timers.protonvpn-portforward = {
          description = "Timer for ProtonVPN NAT-PMP Port Forwarding Renewal";
          wantedBy = [ "timers.target" ];
          after = [ "${vpnCfg.namespace}.service" ];

          timerConfig = {
            OnBootSec = "3min"; # Run 3 minutes after boot (give VPN time to establish)
            OnUnitActiveSec = qbittorrentCfg.vpn.portForwarding.renewInterval; # Renew every 45 minutes
            Unit = "protonvpn-portforward.service";
            Persistent = true; # Run missed timers on boot
            AccuracySec = "1min"; # Allow some jitter
          };
        };

        # Monitoring and diagnostic scripts
        environment.systemPackages = [
          (pkgs.writeShellScriptBin "monitor-protonvpn-portforward" (
            builtins.readFile ../../../../scripts/monitor-protonvpn-portforward.sh
          ))
          (pkgs.writeShellScriptBin "verify-qbittorrent-vpn" (
            builtins.readFile ../../../../scripts/verify-qbittorrent-vpn.sh
          ))
          (pkgs.writeShellScriptBin "test-vpn-port-forwarding" (
            builtins.readFile ../../../../scripts/test-vpn-port-forwarding.sh
          ))
        ];
      };
}
