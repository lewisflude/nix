# Prowlarr - Indexer manager
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement.prowlarr;
in {
  options.host.services.mediaManagement.prowlarr = {
    enable =
      mkEnableOption "Prowlarr indexer manager"
      // {
        default = true;
      };
  };

  config = mkIf (config.host.services.mediaManagement.enable && cfg.enable) {
    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };

    # Run as common media user and set timezone
    systemd.services.prowlarr = {
      serviceConfig = {
        User = config.host.services.mediaManagement.user;
        Group = config.host.services.mediaManagement.group;
      };
      environment = {
        TZ = config.host.services.mediaManagement.timezone;
      };
    };
  };
}
