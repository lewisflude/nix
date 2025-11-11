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
    # Enable systemd-networkd
    systemd.network.enable = true;
    networking.useNetworkd = true;

    # Allow WireGuard port
    networking.firewall.allowedUDPPorts = [ 51820 ];

    # Configure reverse path filtering to allow VPN traffic
    networking.firewall.checkReversePath = "loose";

    systemd.network = {
      netdevs."50-${cfg.interfaceName}" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = cfg.interfaceName;
        };

        wireguardConfig = {
          ListenPort = 51820;
          PrivateKeyFile = cfg.privateKeyFile;
          FirewallMark = cfg.firewallMark;
          RouteTable = cfg.routeTable;
        };

        wireguardPeers = map (
          peer:
          {
            inherit (peer) publicKey allowedIPs;
          }
          // lib.optionalAttrs (peer.endpoint != null) {
            inherit (peer) endpoint;
          }
          // lib.optionalAttrs (peer.persistentKeepalive != null) {
            inherit (peer) persistentKeepalive;
          }
        ) cfg.peers;
      };

      networks."50-${cfg.interfaceName}" = {
        matchConfig.Name = cfg.interfaceName;

        address = cfg.address;
        dns = cfg.dns;

        # DNS settings for systemd-resolved
        networkConfig = {
          DNSDefaultRoute = true;
        };

        routingPolicyRules =
          # Higher priority rule (30000): Route local networks through main table
          (map (network: {
            Family = "both";
            To = network;
            Table = "main";
            User = cfg.user;
            Priority = 30000;
          }) cfg.localNetworks)
          ++
          # Lower priority rule (30001): Route all other traffic through VPN table
          [
            {
              Family = "both";
              Table = cfg.routeTable;
              User = cfg.user;
              Priority = 30001;
            }
          ];
      };
    };
  };
}
