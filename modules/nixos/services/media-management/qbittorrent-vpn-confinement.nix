{
  config,
  lib,
  pkgs,
  constants,
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
      default = constants.hosts.jupiter.ipv4;
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

    boot.kernel.sysctl = {
      "net.core.rmem_default" = 262144;
      "net.core.wmem_default" = 262144;
      "net.core.rmem_max" = 33554432;
      "net.core.wmem_max" = 33554432;
      "net.ipv4.udp_rmem_min" = 16384;
      "net.ipv4.udp_wmem_min" = 16384;
    };

    environment.systemPackages = [
      pkgs.wireguard-tools
      pkgs.libnatpmp
      pkgs.iproute2
    ];

    # Configure SOPS secret for WireGuard configuration
    sops.secrets.${vpnCfg.wireguardConfig} = {
      restartUnits = [ "${vpnCfg.namespace}.service" ];
    };

    environment.etc."netns/${vpnCfg.namespace}/nsswitch.conf".text = ''
      passwd:    files
      group:     files
      shadow:    files
      hosts:     files dns
      networks:  files
      ethers:    files
      services:  files
      protocols: files
      rpc:       files
    '';

    vpnNamespaces.${vpnCfg.namespace} = {
      enable = true;
      wireguardConfigFile = config.sops.secrets.${vpnCfg.wireguardConfig}.path;

      accessibleFrom = [ constants.networks.lan.primary ];

      portMappings = [
        {
          from = constants.ports.services.qbittorrent;
          to = 8080;
        }
        {
          from = constants.ports.services.transmission;
          to = 9091;
        }
      ];

      openVPNPorts = [
        {
          port = vpnCfg.torrentPort;
          protocol = "both";
        }
      ];
    };

    systemd.services = {
      qbittorrent = {
        vpnConfinement = {
          enable = true;
          vpnNamespace = vpnCfg.namespace;
        };
        wants = [ "network-online.target" ];
        serviceConfig = { };
      };

      "configure-qbt-routes" = {
        description = "Configure routes for qBittorrent VPN namespace";
        after = [ "qbittorrent.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStart = "${pkgs.iproute2}/bin/ip netns exec ${vpnCfg.namespace} ${pkgs.iproute2}/bin/ip route add ${constants.networks.vpn.cidr} dev ${vpnCfg.namespace}0";
          SuccessExitStatus = [
            0
            2
          ];
        };
      };

      "configure-qbt-qdisc" = {
        description = "Configure traffic control qdisc for qBittorrent WireGuard interface";
        after = [ "${vpnCfg.namespace}.service" ];
        before = [ "qbittorrent.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStart = "${pkgs.iproute2}/bin/ip netns exec ${vpnCfg.namespace} ${pkgs.iproute2}/bin/tc qdisc replace dev ${vpnCfg.namespace}0 root cake bandwidth 100mbit overhead 60 mpu 64";
          ExecStop = "${pkgs.iproute2}/bin/ip netns exec ${vpnCfg.namespace} ${pkgs.iproute2}/bin/tc qdisc del dev ${vpnCfg.namespace}0 root || true";
        };
      };
    };
  };
}
