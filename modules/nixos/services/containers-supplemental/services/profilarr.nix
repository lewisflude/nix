{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.host.services.containersSupplemental;
in
{
  options.host.services.containersSupplemental.profilarr = {
    enable = mkEnableOption "Profilarr configuration management tool for Radarr/Sonarr" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for Profilarr" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.profilarr.enable) {
    virtualisation.oci-containers.containers.profilarr = {
      image = "santiagosayshey/profilarr:latest";
      environment = {
        TZ = cfg.timezone;
      };
      volumes = [
        "${cfg.configPath}/profilarr:/config"
      ];
      ports = [ "6868:6868" ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.configPath}/profilarr 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.profilarr.openFirewall [
      constants.ports.services.profilarr
    ];
  };
}
