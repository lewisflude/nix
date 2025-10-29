# Jellyseerr - Request management
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
  options.host.services.mediaManagement.jellyseerr.enable =
    mkEnableOption "Jellyseerr request management"
    // {
      default = true;
    };

  config = mkIf (cfg.enable && cfg.jellyseerr.enable) {
    services.jellyseerr = {
      enable = true;
      openFirewall = true;
      port = 5055;
    };

    systemd.services.jellyseerr = {
      # Soft dependency on jellyfin and shared runtime configuration
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
