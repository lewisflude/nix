# Lidarr - Music management
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.lidarr.enable = mkEnableOption "Lidarr music management" // {
    default = true;
  };

  config = mkIf (cfg.enable && cfg.lidarr.enable) {
    services.lidarr = {
      enable = true;
      openFirewall = true;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    # Set timezone and add soft dependency on prowlarr
    systemd.services.lidarr = {
      environment = {
        TZ = cfg.timezone;
      };
      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };
  };
}
