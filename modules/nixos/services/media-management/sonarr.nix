{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkAfter;
  inherit (lib.lists) optional;
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.sonarr.enable =
    mkEnableOption "Sonarr TV show management"
    // {
      default = true;
    };

  config = mkIf (cfg.enable && cfg.sonarr.enable) {
    services.sonarr = {
      enable = true;
      openFirewall = true;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    systemd.services.sonarr = {
      environment = {
        TZ = cfg.timezone;
      };

      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };
  };
}
