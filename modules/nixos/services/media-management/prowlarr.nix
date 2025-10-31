# Prowlarr - Indexer manager
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
  options.host.services.mediaManagement.prowlarr.enable =
    mkEnableOption "Prowlarr indexer manager"
    // {
      default = true;
    };

  config = mkIf (cfg.enable && cfg.prowlarr.enable) {
    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };

    # Run as common media user and set timezone
    systemd.services.prowlarr = {
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
      };
      environment = {
        TZ = cfg.timezone;
      };
    };
  };
}
