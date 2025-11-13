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

    # Ensure WireGuard tools and natpmpc are available
    # - wireguard-tools: required by VPN-Confinement startup script
    # - libnatpmp: required for ProtonVPN NAT-PMP port forwarding
    # - iproute2: required for ip command in NAT-PMP script
    environment.systemPackages = with pkgs; [
      wireguard-tools
      libnatpmp
      iproute2
    ];

    # Configure SOPS secret for WireGuard configuration
    sops.secrets.${vpnCfg.wireguardConfig} = {
      restartUnits = [ "vpn-${vpnCfg.namespace}.service" ];
    };

    # Configure VPN namespace for qBittorrent
    vpnNamespaces.${vpnCfg.namespace} = {
      enable = true;

      # WireGuard configuration from SOPS
      wireguardConfigFile = config.sops.secrets.${vpnCfg.wireguardConfig}.path;

      # IMPORTANT: MTU must be configured in the WireGuard config file itself
      # Add "MTU = 1436" to the [Interface] section of your WireGuard config
      # Standard MTU (1500) + WireGuard overhead (64 bytes) would exceed link MTU
      # WireGuard typically needs 1436-1440 to avoid packet fragmentation

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

    # Configure systemd services and timers for qBittorrent VPN and NAT-PMP
    systemd = {
      services = {
        # Configure qBittorrent service for VPN namespace
        qbittorrent = {
          vpnConfinement = {
            enable = true;
            vpnNamespace = vpnCfg.namespace;
          };
          # Ensure qbittorrent service depends on network setup
          wants = [ "network-online.target" ];
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

        # Systemd service for ProtonVPN NAT-PMP port forwarding
        # Discovers the forwarded port and saves it for monitoring/logging
        # NOTE: natpmpc MUST run on the host, not in the namespace (UDP responses don't reach namespace)
        "protonvpn-natpmp" = {
          description = "ProtonVPN NAT-PMP Port Forwarding Discovery";
          after = [ "vpn-${vpnCfg.namespace}.service" ];
          before = [ "qbittorrent.service" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = "yes";

            # Run with elevated privileges to access natpmpc
            User = "root";

            # Path to the script (4 levels up to repo root: modules/nixos/services/media-management -> repo root)
            ExecStart = "${pkgs.bash}/bin/bash ${../../../../scripts/protonvpn-natpmp-portforward.sh}";

            # Environment variables for the script
            # Use absolute paths for tools since PATH expansion can be unreliable in systemd
            Environment = [
              "NAMESPACE=${vpnCfg.namespace}"
              "VPN_GATEWAY=10.2.0.1"
              "QBT_PORT=${toString vpnCfg.torrentPort}"
              "IP_BIN=${pkgs.iproute2}/bin/ip"
              "GREP_BIN=${pkgs.gnugrep}/bin/grep"
              "NATPMPC_BIN=${pkgs.libnatpmp}/bin/natpmpc"
            ];

            # Restart if it fails, but with a delay to allow VPN to fully establish
            Restart = "on-failure";
            RestartSec = "10s";
            StartLimitIntervalSec = "60";
            StartLimitBurst = "3";
          };
        };
      };

      # Timer to periodically refresh the NAT-PMP port mapping
      # ProtonVPN port mappings expire after 3600 seconds (1 hour)
      # Refresh every 50 minutes to stay within the lease time
      timers."protonvpn-natpmp" = {
        description = "Periodic ProtonVPN NAT-PMP Port Forwarding Refresh";
        wantedBy = [ "timers.target" ];

        timerConfig = {
          # Run 50 minutes after boot, then every 50 minutes
          OnBootSec = "50min";
          OnUnitActiveSec = "50min";
          Unit = "protonvpn-natpmp.service";
        };
      };
    };
  };
}
