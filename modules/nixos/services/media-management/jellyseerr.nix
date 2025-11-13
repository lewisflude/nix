{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkAfter;
  inherit (lib.lists) optional;
  cfg = config.host.services.mediaManagement;
  constants = import ../../../../lib/constants.nix;
in
{
  options.host.services.mediaManagement.jellyseerr.enable =
    mkEnableOption "Jellyseerr request management"
    // {
      default = true;
    };

  config = mkIf (cfg.enable && cfg.jellyseerr.enable) {
    services.jellyseerr = {
      enable = true;
      openFirewall = true;
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
