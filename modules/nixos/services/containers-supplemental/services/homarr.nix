{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  containersLib = import ../lib.nix { inherit lib; };
  inherit (containersLib) mkResourceOptions mkResourceFlags mkHealthFlags;

  cfg = config.host.services.containersSupplemental;
in
{
  options.host.services.containersSupplemental.homarr = {
    enable = mkEnableOption "Homarr dashboard" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for Homarr" // {
      default = true;
    };

    resources = mkResourceOptions {
      memory = "512m";
      cpus = "0.5";
    };
  };

  config = mkIf (cfg.enable && cfg.homarr.enable) {
    virtualisation.oci-containers.containers.homarr = {
      image = "ghcr.io/ajnart/homarr:0.15.3";
      environment = {
        TZ = cfg.timezone;
      };
      volumes = [
        "${cfg.configPath}/homarr/configs:/app/data/configs"
        "${cfg.configPath}/homarr/icons:/app/public/icons"
        "${cfg.configPath}/homarr/data:/data"
      ];
      ports = [ "${toString constants.ports.services.homarr}:7575" ];
      extraOptions =
        mkHealthFlags {
          cmd = "wget --no-verbose --tries=1 --spider http://localhost:7575/ || exit 1";
        }
        ++ mkResourceFlags cfg.homarr.resources;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.configPath}/homarr 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${cfg.configPath}/homarr/configs 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${cfg.configPath}/homarr/icons 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${cfg.configPath}/homarr/data 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.homarr.openFirewall [
      constants.ports.services.homarr
    ];
  };
}
