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

    # Deliberately NOT opened in the firewall. etserver is a remote shell that
    # rides SSH auth, so it gets the same treatment as sshd (see ssh.nix):
    # eno2 carries LAN and router-forwarded WAN traffic alike, and leaving 2022
    # world-open while closing 22 would be incoherent. tailscale0 is a trusted
    # interface (tailscale.nix), so `et jupiter` still works over the tailnet.
    # To go back to a network-open port, restore:
    #   networking.firewall.allowedTCPPorts = [
    #     constants.ports.services.eternalTerminal
    #   ];
  };

  # Darwin intentionally omitted: nix-darwin's services.eternal-terminal
  # mis-models etserver's self-daemonize under launchd (parent forks and
  # exits, launchd records EX_CONFIG=78 and refuses to restart). Use mosh
  # over SSH on macOS instead.
}
