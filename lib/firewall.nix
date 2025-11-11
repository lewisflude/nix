{ lib }:
let
  # Helper functions for services to declare firewall rules
  # These functions create option structures that can be merged into networking.firewall

  # Declare TCP ports that a service needs
  declareTCPPorts = ports: {
    networking.firewall.allowedTCPPorts = ports;
  };

  # Declare UDP ports that a service needs
  declareUDPPorts = ports: {
    networking.firewall.allowedUDPPorts = ports;
  };

  # Declare TCP port ranges that a service needs
  declareTCPPortRanges = ranges: {
    networking.firewall.allowedTCPPortRanges = ranges;
  };

  # Declare UDP port ranges that a service needs
  declareUDPPortRanges = ranges: {
    networking.firewall.allowedUDPPortRanges = ranges;
  };

  # Declare firewall rules for a service (combines TCP and UDP ports)
  declareFirewallRules =
    {
      tcpPorts ? [ ],
      udpPorts ? [ ],
      tcpPortRanges ? [ ],
      udpPortRanges ? [ ],
    }:
    {
      networking.firewall = lib.mkMerge [
        (lib.optionalAttrs (tcpPorts != [ ]) { allowedTCPPorts = tcpPorts; })
        (lib.optionalAttrs (udpPorts != [ ]) { allowedUDPPorts = udpPorts; })
        (lib.optionalAttrs (tcpPortRanges != [ ]) { allowedTCPPortRanges = tcpPortRanges; })
        (lib.optionalAttrs (udpPortRanges != [ ]) { allowedUDPPortRanges = udpPortRanges; })
      ];
    };

  # Helper to create a port range object
  mkPortRange = from: to: { inherit from to; };

  firewallLib = {
    inherit
      declareTCPPorts
      declareUDPPorts
      declareTCPPortRanges
      declareUDPPortRanges
      declareFirewallRules
      mkPortRange
      ;
  };
in
firewallLib
