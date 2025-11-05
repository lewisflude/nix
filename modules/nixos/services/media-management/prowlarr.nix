# Prowlarr - Indexer manager
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.host.services.mediaManagement.prowlarr;
in
{
  options.host.services.mediaManagement.prowlarr = {
    enable = mkEnableOption "Prowlarr indexer manager" // {
      default = true;
    };
  };

  config = mkIf (config.host.services.mediaManagement.enable && cfg.enable) {
    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };

    # Set timezone, user, and group via systemd
    systemd.services.prowlarr = {
      environment = {
        TZ = config.host.services.mediaManagement.timezone;
      };
      serviceConfig = {
        User = config.host.services.mediaManagement.user;
        Group = config.host.services.mediaManagement.group;
      };
    };
  };
}
