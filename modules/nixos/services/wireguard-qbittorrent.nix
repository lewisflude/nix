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

  cfg = config.services.wireguard-qbittorrent;
in
{
  options.services.wireguard-qbittorrent = {
    enable = mkEnableOption "WireGuard VPN for qBittorrent with user-specific routing";

    interfaceName = mkOption {
      type = types.str;
      default = "qbittor0";
      description = "Name of the WireGuard interface";
    };

    user = mkOption {
      type = types.str;
      default = "media";
      description = "User whose traffic should be routed through the VPN";
    };

    privateKeyFile = mkOption {
      type = types.path;
      description = "Path to WireGuard private key file";
    };

    address = mkOption {
      type = types.listOf types.str;
      default = [ "10.2.0.2/32" ];
      description = "WireGuard interface addresses";
    };

    dns = mkOption {
      type = types.listOf types.str;
      default = [ "10.2.0.1" ];
      description = "DNS servers for the VPN connection";
    };

    peers = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            publicKey = mkOption {
              type = types.str;
              description = "Public key of the peer";
            };
            allowedIPs = mkOption {
              type = types.listOf types.str;
              default = [
                "0.0.0.0/0"
                "::/0"
              ];
              description = "Allowed IPs for this peer";
            };
            endpoint = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Endpoint address for this peer";
            };
            persistentKeepalive = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "Persistent keepalive interval";
            };
          };
        }
      );
      default = [ ];
      description = "WireGuard peers configuration";
    };

    localNetworks = mkOption {
      type = types.listOf types.str;
      default = [
        "192.168.1.0/24"
        "127.0.0.1/32"
        "::1/128"
      ];
      description = "Local networks that should bypass the VPN";
    };

    firewallMark = mkOption {
      type = types.int;
      default = 42;
      description = "Firewall mark for WireGuard packets";
    };

    routeTable = mkOption {
      type = types.int;
      default = 1000;
      description = "Routing table number for VPN routes";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      # Allow WireGuard port
      firewall.allowedUDPPorts = [ 51820 ];

      # Configure reverse path filtering to allow VPN traffic
      firewall.checkReversePath = "loose";

      # Standard WireGuard interface using wg-quick
      wireguard.interfaces.${cfg.interfaceName} = {
        inherit (cfg) peers privateKeyFile;
        ips = cfg.address;
        listenPort = 51820;
      };
    };

    # User-specific routing via robust systemd service
    systemd.services.wireguard-routing = {
      description = "WireGuard routing for ${cfg.user}";
      after = [
        "network.target"
        "wireguard-${cfg.interfaceName}.service"
      ];
      requires = [ "wireguard-${cfg.interfaceName}.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart =
          let
            userId = config.users.users.${cfg.user}.uid;
            rules = [
              # Route traffic from the specified user through the VPN routing table
              "ip rule add from ${toString userId} table ${toString cfg.routeTable} priority 30001"
            ]
            ++ lib.concatMap (network: [
              # Route traffic to local networks through main table (bypass VPN)
              "ip rule add to ${network} table main priority 30000"
            ]) cfg.localNetworks;
          in
          "${pkgs.bash}/bin/bash -c '${lib.concatStringsSep "; " rules} || true'";
        ExecStop =
          let
            userId = config.users.users.${cfg.user}.uid;
            rules = [
              # Remove user routing rule
              "ip rule del from ${toString userId} table ${toString cfg.routeTable} priority 30001"
            ]
            ++ lib.concatMap (network: [
              # Remove local network bypass rules
              "ip rule del to ${network} table main priority 30000"
            ]) cfg.localNetworks;
          in
          "${pkgs.bash}/bin/bash -c '${lib.concatStringsSep "; " rules} || true'";
      };
    };
  };
}
