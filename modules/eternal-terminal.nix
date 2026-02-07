# Eternal Terminal Service Module - Dendritic Pattern
# Persistent remote terminal with reconnection support
# Usage: Import flake.modules.nixos.eternalTerminal in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.eternalTerminal =
    { ... }:
    {
      services.eternal-terminal = {
        enable = true;
        port = constants.ports.services.eternalTerminal;
      };

      networking.firewall.allowedTCPPorts = [
        constants.ports.services.eternalTerminal
      ];
    };
}
