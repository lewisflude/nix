{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.host.services.eternal-terminal;
in
{
  options.host.services.eternal-terminal = {
    enable = mkEnableOption "Eternal Terminal (SSH alternative)" // {
      default = true;
    };
    openFirewall = mkEnableOption "Open firewall ports for Eternal Terminal" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
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
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
      constants.ports.services.eternalTerminal
    ];
  };
}
