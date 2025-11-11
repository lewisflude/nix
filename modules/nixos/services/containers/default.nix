{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.host.services.containers;
in
{
  imports = [
    ./productivity.nix
    ./secrets.nix
  ];

  options.host.services.containers = {
    enable = mkEnableOption "container services";

    productivity = {
      enable = mkEnableOption "productivity stack (AI tools)";
      configPath = mkOption {
        type = types.str;
        default = "/var/lib/containers/productivity";
        description = "Path to store container configurations";
      };
      enableCup = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Container Update Proxy (full podman.sock access); leave disabled unless you explicitly trust the image.";
      };
    };

    timezone = mkOption {
      type = types.str;
      default = "Europe/London";
      description = "Timezone for all containers";
    };

    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "User ID for container processes";
    };

    gid = mkOption {
      type = types.int;
      default = 100;
      description = "Group ID for container processes";
    };
  };

  config = mkIf cfg.enable {

    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    hardware.nvidia-container-toolkit.enable = config.hardware.nvidia.modesetting.enable or false;

    virtualisation.oci-containers.backend = "podman";

    systemd.tmpfiles.rules =
      let
        mkContainerDirs = path: [
          "d ${path} 0755 root root -"
          "d ${path}/config 0755 ${toString cfg.uid} ${toString cfg.gid} -"
        ];

        prodRules = if cfg.productivity.enable then mkContainerDirs cfg.productivity.configPath else [ ];
      in
      prodRules;
  };
}
