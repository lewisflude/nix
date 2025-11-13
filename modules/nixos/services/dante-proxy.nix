{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.services.dante-proxy;
in
{
  options.services.dante-proxy = {
    enable = mkEnableOption "Dante SOCKS proxy server bound to vlan2";

    port = mkOption {
      type = types.port;
      default = 1080;
      description = "Port to listen on for SOCKS connections";
    };

    interface = mkOption {
      type = types.str;
      default = "vlan2";
      description = "Network interface to bind the proxy to (for routing through specific network)";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to listen on (0.0.0.0 = all interfaces, 127.0.0.1 = localhost only)";
    };

    allowedClients = mkOption {
      type = types.listOf types.str;
      default = [
        "127.0.0.1/32"
        "192.168.0.0/16"
      ];
      description = "List of client IP addresses/ranges allowed to connect";
      example = [
        "127.0.0.1/32"
        "192.168.1.0/24"
      ];
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall port for the proxy";
    };

    enableAuthentication = mkOption {
      type = types.bool;
      default = false;
      description = "Enable username/password authentication (requires users to be defined)";
    };
  };

  config = mkIf cfg.enable {
    services.dante = {
      enable = true;
      config = ''
        # Logging
        logoutput: syslog

        # Internal interface - where the proxy listens for connections
        internal: ${cfg.listenAddress} port=${toString cfg.port}

        # External interface - where the proxy sends traffic (through vlan2)
        external: ${cfg.interface}

        # SOCKS authentication method (global setting)
        socksmethod: ${if cfg.enableAuthentication then "username" else "none"}

        # Client access rules
        ${lib.concatMapStringsSep "\n" (
          client: "client pass { from: ${client} to: 0.0.0.0/0 }"
        ) cfg.allowedClients}

        # Target access rules - allow all destinations
        socks pass {
          from: 0.0.0.0/0 to: 0.0.0.0/0
          protocol: tcp udp
        }
      '';
    };

    # Open firewall if requested
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };

    # Ensure the interface exists (systemd dependency)
    systemd.services.dante = {
      after = [
        "network-online.target"
        "sys-subsystem-net-devices-${cfg.interface}.device"
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
