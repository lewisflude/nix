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
    mkDefault
    ;

  cfg = config.host.services.containersSupplemental;
in
{
  imports = [
    ./services/homarr.nix
    ./services/wizarr.nix
    ./services/doplarr.nix
    ./services/comfyui.nix
    ./services/calcom.nix
    ./services/janitorr.nix
    ./services/jellystat.nix
    ./services/termix.nix
    ./services/profilarr.nix
    ./services/cleanuparr.nix
  ];

  options.host.services.containersSupplemental = {
    enable = mkEnableOption "supplemental container services";

    configPath = mkOption {
      type = types.str;
      default = "/var/lib/containers/supplemental";
      description = "Path to store container configurations.";
    };

    timezone = mkOption {
      type = types.str;
      default = "Europe/London";
      description = "Timezone for all containers.";
    };

    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "User ID for container processes.";
    };

    gid = mkOption {
      type = types.int;
      default = 100;
      description = "Group ID for container processes.";
    };
  };

  config = mkIf cfg.enable {
    # Podman configuration is handled by host.features.virtualisation
    # This module only configures OCI container services
    virtualisation.oci-containers.backend = "podman";

    systemd.tmpfiles.rules = [
      "d ${cfg.configPath} 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];

    # Ensure virtualisation feature is enabled with Podman
    assertions = [
      {
        assertion = config.virtualisation.podman.enable or false;
        message = "containersSupplemental requires Podman to be enabled via host.features.virtualisation.podman = true";
      }
    ];
  };
}
