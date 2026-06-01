# Eternal Terminal Service Module - Dendritic Pattern
# Persistent remote terminal with reconnection support
# Usage: Import flake.modules.nixos.eternalTerminal in host definition
{ config, ... }:
let
  inherit (config) constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.eternalTerminal = _: {
    services.eternal-terminal = {
      enable = true;
      port = constants.ports.services.eternalTerminal;
    };

    networking.firewall.allowedTCPPorts = [
      constants.ports.services.eternalTerminal
    ];
  };

  # Darwin intentionally omitted: nix-darwin's services.eternal-terminal
  # mis-models etserver's self-daemonize under launchd (parent forks and
  # exits, launchd records EX_CONFIG=78 and refuses to restart). Use mosh
  # over SSH on macOS instead.
}
