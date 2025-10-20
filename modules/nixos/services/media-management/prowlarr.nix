# Prowlarr - Indexer manager
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
  config = mkIf (cfg.enable && cfg.prowlarr.enable) {
    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };

    # Run as common media user
    systemd.services.prowlarr = {
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
      };
    };

    # Set timezone via environment
    systemd.services.prowlarr.environment = {
      TZ = cfg.timezone;
    };
  };
}
