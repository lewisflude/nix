# Radarr - Movie management
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
  options.host.services.mediaManagement.radarr.enable =
    mkEnableOption "Radarr movie management"
    // {
      default = true;
    };

  config = mkIf (cfg.enable && cfg.radarr.enable) {
    services.radarr = {
      enable = true;
      openFirewall = true;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    # Set timezone and add soft dependency on prowlarr
    systemd.services.radarr = {
      environment = {
        TZ = cfg.timezone;
      };
      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };
  };
}
