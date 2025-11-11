{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  containersLib = import ../lib.nix { inherit lib; };
  inherit (containersLib) mkResourceOptions mkResourceFlags mkHealthFlags;

  cfg = config.host.services.containersSupplemental;
in
{
  options.host.services.containersSupplemental.profilarr = {
    enable = mkEnableOption "Profilarr configuration management tool for Radarr/Sonarr" // {
      default = true;
    };

    resources = mkResourceOptions {
      memory = "512m";
      cpus = "0.5";
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
      extraOptions =
        mkHealthFlags {
          cmd = "wget --no-verbose --tries=1 --spider http://localhost:6868/ || exit 1";
        }
        ++ mkResourceFlags cfg.profilarr.resources;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.configPath}/profilarr 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];
  };
}