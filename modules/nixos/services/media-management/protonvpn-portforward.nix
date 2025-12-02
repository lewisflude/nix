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
  transmissionCfg = cfg.transmission or { };

  # Port forwarding script with qBittorrent API integration
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
    ]
    ++ lib.optionals (transmissionCfg.enable or false) [
      pkgs.transmission_4 # Provides transmission-remote CLI tool
    ];
    text = builtins.readFile ../../../../scripts/protonvpn-natpmp-portforward.sh;
  };

  # Firewall updater script - dynamically opens the forwarded port
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

    # IPv4: Remove old port rules (if any exist for ports that aren't the new port)
    ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/iptables-save | \
      grep -E "qbt0.*dpt:[0-9]+" | grep -v "dpt:$NEW_PORT" | \
      sed 's/^-A /-D /' | while read rule; do
        ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/iptables $rule 2>/dev/null || true
      done || true  # Don't fail if no old rules exist

    # IPv4: Add rules for new port if they don't exist
    if ! ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/iptables -C INPUT -p tcp --dport "$NEW_PORT" -i qbt0 -j ACCEPT 2>/dev/null; then
      ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/iptables -I INPUT -p tcp --dport "$NEW_PORT" -i qbt0 -j ACCEPT
      echo "Added IPv4 TCP rule for port $NEW_PORT"
    fi

    if ! ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/iptables -C INPUT -p udp --dport "$NEW_PORT" -i qbt0 -j ACCEPT 2>/dev/null; then
      ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/iptables -I INPUT -p udp --dport "$NEW_PORT" -i qbt0 -j ACCEPT
      echo "Added IPv4 UDP rule for port $NEW_PORT"
    fi

    # IPv6: Remove old port rules (if any exist for ports that aren't the new port)
    ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/ip6tables-save | \
      grep -E "qbt0.*dpt:[0-9]+" | grep -v "dpt:$NEW_PORT" | \
      sed 's/^-A /-D /' | while read rule; do
        ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/ip6tables $rule 2>/dev/null || true
      done || true  # Don't fail if no old rules exist

    # IPv6: Add rules for new port if they don't exist
    if ! ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/ip6tables -C INPUT -p tcp --dport "$NEW_PORT" -i qbt0 -j ACCEPT 2>/dev/null; then
      ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/ip6tables -I INPUT -p tcp --dport "$NEW_PORT" -i qbt0 -j ACCEPT
      echo "Added IPv6 TCP rule for port $NEW_PORT"
    fi

    if ! ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/ip6tables -C INPUT -p udp --dport "$NEW_PORT" -i qbt0 -j ACCEPT 2>/dev/null; then
      ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iptables}/bin/ip6tables -I INPUT -p udp --dport "$NEW_PORT" -i qbt0 -j ACCEPT
      echo "Added IPv6 UDP rule for port $NEW_PORT"
    fi

    echo "Firewall updated successfully for port $NEW_PORT (IPv4 + IPv6)"
  '';
in
{
  options.host.services.mediaManagement.qbittorrent.vpn.portForwarding = {
    enable = mkEnableOption "Automatic ProtonVPN port forwarding via NAT-PMP" // {
      default = true;
    };

    renewInterval = mkOption {
      type = types.str;
      default = "45s";
      description = "How often to renew the port forwarding lease (ProtonVPN official: 60s lease, 45s renewal)";
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
        systemd.services.protonvpn-portforward = {
          description = "ProtonVPN NAT-PMP Port Forwarding with qBittorrent Integration";
          after = [
            "network-online.target"
            "${vpnCfg.namespace}.service"
            "qbittorrent.service"
            "configure-qbt-routes.service"
          ];
          wants = [
            "network-online.target"
            "${vpnCfg.namespace}.service"
          ];

          serviceConfig =
            let
              transmissionCfg = config.host.services.mediaManagement.transmission or { };
              transmissionEnabled = transmissionCfg.enable or false;
              useSops =
                transmissionEnabled
                && (transmissionCfg.authentication != null)
                && (transmissionCfg.authentication.useSops or false);
            in
            {
              Type = "oneshot";

              # Main script that queries NAT-PMP and updates qBittorrent
              ExecStart = "${portforwardScript}/bin/protonvpn-portforward";

              # Update firewall with the new port
              ExecStartPost = "${pkgs.bash}/bin/bash -c '${firewallScript} ${qbittorrentCfg.vpn.portForwarding.namespace} $(cat /var/lib/protonvpn-portforward.state | grep PUBLIC_PORT | cut -d= -f2)'";

              # Environment - pass configuration to script
              Environment =
                let
                  # Only enable Transmission port forwarding if explicitly enabled
                  transmissionPortForwardingEnabled =
                    transmissionEnabled && (transmissionCfg.vpn.portForwarding or false);
                in
                [
                  "NAMESPACE=${qbittorrentCfg.vpn.portForwarding.namespace}"
                  "VPN_GATEWAY=${qbittorrentCfg.vpn.portForwarding.gateway}"
                  "NATPMPC_BIN=${pkgs.libnatpmp}/bin/natpmpc"
                  "CURL_BIN=${pkgs.curl}/bin/curl"
                  # Transmission integration
                  "TRANSMISSION_HOST=127.0.0.1:${toString (transmissionCfg.webUIPort or 9091)}"
                  "TRANSMISSION_ENABLED=${if transmissionPortForwardingEnabled then "true" else "false"}"
                ];
              # Note: Transmission credentials are loaded via LoadCredential below
              # The script reads them from $CREDENTIALS_DIRECTORY/transmission-{username,password}

              # Load SOPS secrets as credentials if Transmission uses SOPS
              LoadCredential = lib.mkIf useSops [
                "transmission-username:/run/secrets/transmission/rpc/username"
                "transmission-password:/run/secrets/transmission/rpc/password"
              ];

              # Timeout settings
              TimeoutStartSec = "60s";

              # Security
              PrivateTmp = true;
              NoNewPrivileges = false; # Needed for ip netns exec and iptables
              ProtectSystem = "strict";
              ProtectHome = true;
              ReadWritePaths = [
                "/var/lib" # Need to write state file
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
            OnBootSec = "1min"; # Run 1 minute after boot (give VPN time to establish)
            OnUnitActiveSec = qbittorrentCfg.vpn.portForwarding.renewInterval; # Renew every 45 seconds (per ProtonVPN official docs)
            Unit = "protonvpn-portforward.service";
            Persistent = true; # Run missed timers on boot
            AccuracySec = "1min"; # Allow some jitter
          };
        };

        # Monitoring and diagnostic scripts
        environment.systemPackages = [
          # NAT-PMP tools for manual testing
          pkgs.libnatpmp

          # Port forwarding automation script (can be run manually)
          portforwardScript

          # Helper to show current port
          (pkgs.writeShellScriptBin "show-protonvpn-port" (
            builtins.readFile ../../../../scripts/show-protonvpn-port.sh
          ))

          # Diagnostic scripts
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
