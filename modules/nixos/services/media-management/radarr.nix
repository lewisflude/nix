{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkAfter
    optional
    ;
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.radarr = {
    enable = mkEnableOption "Radarr movie management" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for Radarr" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.radarr.enable) {
    services.radarr = {
      enable = true;
      openFirewall = false;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.radarr.openFirewall [
      constants.ports.services.radarr
    ];

    systemd.services.radarr = {
      environment = {
        TZ = cfg.timezone;
      };
      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };
  };
}
