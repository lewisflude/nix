# SABnzbd - Usenet downloader
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
  options.host.services.mediaManagement.sabnzbd.enable =
    mkEnableOption "SABnzbd usenet downloader"
    // {
      default = true;
    };

  config = mkIf (cfg.enable && cfg.sabnzbd.enable) {
    services.sabnzbd = {
      enable = true;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    # Set timezone
    systemd.services.sabnzbd.environment = {
      TZ = cfg.timezone;
    };

    # Open firewall on port 8082 (mapped from default 8080)
    networking.firewall.allowedTCPPorts = mkAfter [8082];
  };
}
