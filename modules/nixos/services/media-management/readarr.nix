{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkAfter;
  inherit (lib.lists) optional;
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.readarr = {
    enable = mkEnableOption "Readarr book management" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for Readarr" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.readarr.enable) {
    services.readarr = {
      enable = true;
      openFirewall = false;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.readarr.openFirewall [
      constants.ports.services.readarr
    ];

    systemd.services.readarr = {
      environment = {
        TZ = cfg.timezone;
      };
      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };
  };
}
