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
  options.host.services.containersSupplemental.wizarr = {
    enable = mkEnableOption "Wizarr invitation system" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for Wizarr" // {
      default = true;
    };

    resources = mkResourceOptions {
      memory = "256m";
      cpus = "0.25";
    };
  };

  config = mkIf (cfg.enable && cfg.wizarr.enable) {
    virtualisation.oci-containers.containers.wizarr = {
      image = "ghcr.io/wizarrrr/wizarr:4.1.1";
      environment = {
        TZ = cfg.timezone;
      };
      volumes = [ "${cfg.configPath}/wizarr:/data/database" ];
      ports = [ "5690:5690" ];
      extraOptions =
        mkHealthFlags {
          cmd = "wget --no-verbose --tries=1 --spider http://localhost:5690/ || exit 1";
        }
        ++ mkResourceFlags cfg.wizarr.resources;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.configPath}/wizarr 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.wizarr.openFirewall [ 5690 ];
  };
}
