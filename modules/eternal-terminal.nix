# Eternal Terminal Service Module - Dendritic Pattern
# Automatically reconnecting SSH alternative with port forwarding
# Usage: Import flake.modules.nixos.eternalTerminal in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.eternalTerminal = { lib, ... }:
  let
    inherit (lib) mkDefault;
  in
  {
    # Eternal Terminal (ET) - Automatically reconnecting SSH alternative
    # More feature-rich than mosh with bidirectional port forwarding and scrollback support
    services.eternal-terminal = {
      enable = true;

      # Standard ET port (TCP 2022)
      port = constants.ports.services.eternalTerminal;

      # Reasonable log size (10MB default)
      # Logs rotation prevents disk space issues
      logSize = 10485760;

      # Disable silent mode - keep logging enabled for troubleshooting
      silent = false;

      # Moderate verbosity (0-9 scale, 5 is balanced)
      # 0 = minimal, 9 = very verbose
      verbosity = 5;
    };

    # Open firewall for ET connections (mkDefault allows hosts to override)
    networking.firewall.allowedTCPPorts = mkDefault [
      constants.ports.services.eternalTerminal
    ];
  };
}
