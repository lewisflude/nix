{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.services.containers;
  prodCfg = cfg.productivity;
in
{
  config = mkIf (cfg.enable && prodCfg.enable) {
    # Note: Ollama and Open WebUI removed - use host.features.aiTools instead
    # Ollama: services.ollama (native NixOS module)
    # Open WebUI: services.open-webui (native NixOS module)
    # See: modules/nixos/services/ai-tools/ and modules/nixos/features/ai-tools.nix

    virtualisation.oci-containers.containers = {

      comfyui-nvidia = {

        image = "mmartial/comfyui-nvidia-docker:1.0.0";

        environment = {
          WANTED_UID = toString cfg.uid;
          WANTED_GID = toString cfg.gid;
          BASE_DIRECTORY = "/basedir";
          SECURITY_LEVEL = "normal";
          NVIDIA_VISIBLE_DEVICES = "all";
          NVIDIA_DRIVER_CAPABILITIES = "all";
        };

        volumes = [
          "${prodCfg.configPath}/comfyui:/comfy/mnt"
          "${prodCfg.configPath}/basedir:/basedir"
        ];

        ports = [ "8188:8188" ];

        extraOptions = [
          "--device=nvidia.com/gpu=all"

          "--memory=16g"
          "--memory-swap=20g"
          "--cpus=8"
        ];
      };
    }
    // (mkIf prodCfg.enableCup {

      cup = {

        image = "ghcr.io/sergi0g/cup:v1.2.0";

        cmd = [
          "serve"
          "-p"
          "1188"
        ];

        volumes = [

          "/run/podman/podman.sock:/var/run/docker.sock"
        ];

        extraOptions = [
          "--network=host"

          "--memory=256m"
          "--cpus=0.5"
        ];
      };
    });

    systemd.tmpfiles.rules = [
      "d ${prodCfg.configPath}/comfyui 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${prodCfg.configPath}/basedir 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];

    systemd.services = {
      podman-comfyui-nvidia.serviceConfig = {
        RestartSec = "10s";
        StartLimitBurst = 10;
        StartLimitIntervalSec = 600;
      };
    };

    hardware.nvidia-container-toolkit.enable = mkIf config.hardware.nvidia.modesetting.enable true;
  };
}
