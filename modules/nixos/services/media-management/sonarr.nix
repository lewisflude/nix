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
  options.host.services.mediaManagement.sonarr = {
    enable = mkEnableOption "Sonarr TV show management" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for Sonarr" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.sonarr.enable) {
    services.sonarr = {
      enable = true;
      openFirewall = false;
      inherit (cfg) user;
      inherit (cfg) group;
      dataDir = "/var/lib/sonarr/.config/Sonarr";
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.sonarr.openFirewall [
      constants.ports.services.sonarr
    ];

    systemd.services.sonarr = {
      environment = {
        TZ = cfg.timezone;
      };
      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };
  };
}
