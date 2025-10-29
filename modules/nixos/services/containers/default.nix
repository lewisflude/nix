# Container services module
# Manages all containerized services using Podman
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.containers;
in {
  imports = [
    ./media-management.nix
    ./productivity.nix
    ./secrets.nix
  ];

  options.host.services.containers = {
    enable = mkEnableOption "container services";

    mediaManagement = {
      enable = mkEnableOption "media management stack (Arr apps)";
      dataPath = mkOption {
        type = types.str;
        default = "/mnt/storage";
        description = "Path to media storage directory";
      };
      configPath = mkOption {
        type = types.str;
        default = "/var/lib/containers/media-management";
        description = "Path to store container configurations";
      };
    };

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

    # Common settings
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
    # Enable Podman with docker compatibility
    # Note: dockerCompat is managed by virtualisation.nix based on docker enablement
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # Needed for GPU support
    hardware.nvidia-container-toolkit.enable = config.hardware.nvidia.modesetting.enable or false;

    # Enable OCI containers backend
    virtualisation.oci-containers.backend = "podman";

    # Create necessary directories
    systemd.tmpfiles.rules = let
      mkContainerDirs = path: [
        "d ${path} 0755 root root -"
        "d ${path}/config 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ];

      mediaRules =
        if cfg.mediaManagement.enable
        then
          mkContainerDirs cfg.mediaManagement.configPath
          ++ [
            "d ${cfg.mediaManagement.dataPath} 0755 ${toString cfg.uid} ${toString cfg.gid} -"
          ]
        else [];

      prodRules =
        if cfg.productivity.enable
        then mkContainerDirs cfg.productivity.configPath
        else [];
    in
      mediaRules ++ prodRules;
  };
}
