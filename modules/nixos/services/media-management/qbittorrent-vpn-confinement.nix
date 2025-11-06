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
        "::1/128"
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

    systemd.services.protonvpn-port-forwarding = {
      description = "ProtonVPN NAT-PMP Port Forwarding for qBittorrent";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

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
