# Sonarr - TV show management
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
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

    # Set timezone and add soft dependency on prowlarr
    systemd.services.sonarr = {
      environment = {
        TZ = cfg.timezone;
      };
      # Soft dependency on prowlarr for startup order
      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };
  };
}
