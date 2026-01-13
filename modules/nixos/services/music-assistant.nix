{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.host.services.music-assistant;
in
{
  options.host.services.music-assistant = {
    enable = mkEnableOption "Music Assistant" // {
      default = true;
    };
    openFirewall = mkEnableOption "Open firewall ports for Music Assistant" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    services.music-assistant = {
      enable = true;
    };

    # Open firewall port for Music Assistant (default port 8095)
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 8095 ];
  };
}
