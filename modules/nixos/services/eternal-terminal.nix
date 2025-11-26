{ constants, ... }:
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

  # Open firewall for ET connections
  networking.firewall.allowedTCPPorts = [ constants.ports.services.eternalTerminal ];
}
