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
  options.host.services.mediaManagement.jellyseerr = {
    enable = mkEnableOption "Jellyseerr request management" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for Jellyseerr" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.jellyseerr.enable) {
    services.jellyseerr = {
      enable = true;
      inherit (cfg.jellyseerr) openFirewall;
      port = constants.ports.services.jellyseerr;
    };

    systemd.services.jellyseerr = {
      after = mkAfter (optional cfg.jellyfin.enable "jellyfin.service");
      environment = {
        TZ = cfg.timezone;
        LOG_LEVEL = "info";
      };
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
      };
    };
  };
}
