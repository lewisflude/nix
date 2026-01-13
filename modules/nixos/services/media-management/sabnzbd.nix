{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.sabnzbd = {
    enable = mkEnableOption "SABnzbd usenet downloader" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for SABnzbd" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.sabnzbd.enable) {
    services.sabnzbd = {
      enable = true;
      inherit (cfg) user group;

      # Settings removed - let SABnzbd manage its own configuration file
      # This prevents NixOS from wiping the config on every service restart
      # You can manually edit /var/lib/sabnzbd/sabnzbd.ini
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.sabnzbd.openFirewall [
      constants.ports.services.sabnzbd
    ];
  };
}
