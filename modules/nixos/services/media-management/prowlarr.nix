{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.host.services.mediaManagement.prowlarr;
  parentCfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.prowlarr = {
    enable = mkEnableOption "Prowlarr indexer manager" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for Prowlarr" // {
      default = true;
    };
  };

  config = mkIf (parentCfg.enable && cfg.enable) {
    services.prowlarr = {
      enable = true;
      openFirewall = false;
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ constants.ports.services.prowlarr ];

    systemd.services.prowlarr = {
      environment = {
        TZ = parentCfg.timezone;
      };
      serviceConfig = {
        User = parentCfg.user;
        Group = parentCfg.group;
      };
    };
  };
}
