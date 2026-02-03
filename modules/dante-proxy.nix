# Dante Proxy Service Module - Dendritic Pattern
# SOCKS proxy server for network routing
# Usage: Import flake.modules.nixos.danteProxy in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.danteProxy = { lib, ... }:
  let
    inherit (lib) mkDefault mkIf concatMapStringsSep;

    # Default configuration (can be overridden by hosts)
    port = constants.ports.services.dante;
    interface = "vlan2";
    listenAddress = constants.networks.all.ipv4;
    allowedClients = [
      constants.networks.localhost.cidr
      constants.networks.lan.secondary
    ];
    openFirewall = false;
    enableAuthentication = false;
  in
  {
    services.dante = {
      enable = true;
      config = ''
        # Logging
        logoutput: syslog

        # Internal interface - where the proxy listens for connections
        internal: ${listenAddress} port=${toString port}

        # External interface - where the proxy sends traffic (through vlan2)
        external: ${interface}

        # SOCKS authentication method (global setting)
        socksmethod: ${if enableAuthentication then "username" else "none"}

        # Client access rules
        ${concatMapStringsSep "\n" (
          client: "client pass { from: ${client} to: ${constants.networks.all.cidr} }"
        ) allowedClients}

        # Target access rules - allow all destinations
        socks pass {
          from: ${constants.networks.all.cidr} to: ${constants.networks.all.cidr}
          protocol: tcp udp
        }
      '';
    };

    # Open firewall if requested
    networking.firewall = mkIf openFirewall {
      allowedTCPPorts = [ port ];
    };

    # Ensure the interface exists (systemd dependency)
    systemd.services.dante = {
      after = [
        "network-online.target"
        "sys-subsystem-net-devices-${interface}.device"
      ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        # Restart if interface goes down
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
