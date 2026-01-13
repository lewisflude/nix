{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkAfter;
  inherit (lib.lists) optional;
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.lidarr = {
    enable = mkEnableOption "Lidarr music management" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for Lidarr" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.lidarr.enable) {
    services.lidarr = {
      enable = true;
      openFirewall = false;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.lidarr.openFirewall [
      constants.ports.services.lidarr
    ];

    systemd.services.lidarr = {
      environment = {
        TZ = cfg.timezone;
      };
      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };
  };
}
