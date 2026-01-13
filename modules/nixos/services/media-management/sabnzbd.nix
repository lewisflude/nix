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

      settings = {
        misc = {
          port = constants.ports.services.sabnzbd;
          host_whitelist = "usenet.blmt.io";
        };
      };
    };

    # Override the systemd service to remove the pre-start script that wipes config
    systemd.services.sabnzbd = {
      serviceConfig = {
        ExecStartPre = lib.mkForce "";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.sabnzbd.openFirewall [
      constants.ports.services.sabnzbd
    ];
  };
}
