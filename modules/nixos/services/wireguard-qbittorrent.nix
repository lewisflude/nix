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

    webUIMark = mkOption {
      type = types.int;
      default = 43;
      description = "Firewall mark for qBittorrent Web UI packets to bypass VPN";
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

      # Standard WireGuard interface using wg-quick (works reliably)
      wireguard.interfaces.${cfg.interfaceName} = {
        inherit (cfg) peers privateKeyFile;
        ips = cfg.address;
        listenPort = 51820;
      };
    };

    # Configure systemd-networkd for policy-based routing
    systemd = {
      network = {
        enable = true;
        networks."50-${cfg.interfaceName}" = {
          matchConfig.Name = cfg.interfaceName;
          inherit (cfg) address;

          # Policy-based routing rules for quarantine user
          # Routes only the quarantine user's traffic through the VPN
          routingPolicyRules = [
            # Priority 30000: Allow local network traffic through main table for quarantine user
            # Uses SuppressPrefixLength to only match rules with non-zero prefix length
            # This ensures 0.0.0.0/0 rules still apply (VPN routing)
            {
              Table = "main";
              User = "quarantine";
              SuppressPrefixLength = 0;
              Priority = 30000;
              Family = "both";
            }

            # Priority 30001: Route all other quarantine user traffic through VPN table
            # This is the catch-all rule that sends quarantine traffic through the WireGuard tunnel
            {
              Table = cfg.routeTable;
              User = "quarantine";
              Priority = 30001;
              Family = "both";
            }
          ];
        };
      };

      # Create the VPN routing table with default gateway through WireGuard
      services.wireguard-routing = {
        description = "Setup WireGuard routing table for quarantine user";
        after = [
          "network.target"
          "wireguard-${cfg.interfaceName}.service"
        ];
        requires = [ "wireguard-${cfg.interfaceName}.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "wireguard-routing-setup" ''
            set -e

            # Wait for interface to be up
            for i in {1..30}; do
              if ${pkgs.iproute2}/bin/ip link show ${cfg.interfaceName} &>/dev/null; then
                break
              fi
              sleep 0.5
            done

            # Add default route via WireGuard interface to custom routing table
            # Note: Point-to-point WireGuard interfaces don't need a gateway IP
            ${pkgs.iproute2}/bin/ip route add default dev ${cfg.interfaceName} table ${toString cfg.routeTable} || true
          '';
        };
      };
    };
  };
}
