# Readarr - Book management
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkAfter;
  inherit (lib.lists) optional;
  cfg = config.host.services.mediaManagement;
in {
  options.host.services.mediaManagement.readarr.enable =
    mkEnableOption "Readarr book management"
    // {
      default = true;
    };

  config = mkIf (cfg.enable && cfg.readarr.enable) {
    services.readarr = {
      enable = true;
      openFirewall = true;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    # Set timezone and add soft dependency on prowlarr
    systemd.services.readarr = {
      environment = {
        TZ = cfg.timezone;
      };
      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };
  };
}
