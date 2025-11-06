{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkAfter;
  cfg = config.host.services.containers;
  prodCfg = cfg.productivity;
in
{
  config = mkIf (cfg.enable && prodCfg.enable) {
    virtualisation.oci-containers.containers = {

      ollama = {

        image = "ollama/ollama:0.1.48";

        environment = {
          OLLAMA_KEEP_ALIVE = "24h";

          HOME = "/data";
        };

        volumes = [ "${prodCfg.configPath}/ollama:/data/.ollama" ];

        extraOptions = [
          "--network=host"
          "--device=nvidia.com/gpu=all"

          "--memory=16g"
          "--cpus=8"
        ];
      };

      openwebui = {

        image = "ghcr.io/open-webui/open-webui:0.3.13-cuda";

        environment = {
          TZ = cfg.timezone;
          OLLAMA_BASE_URL = "http://localhost:11434";
        };

        volumes = [ "${prodCfg.configPath}/openwebui:/app/backend/data" ];
        ports = [ "7000:8080" ];

        extraOptions = [
          "--device=nvidia.com/gpu=all"

          "--memory=8g"
          "--cpus=4"
        ];

      };

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
      "d ${prodCfg.configPath}/ollama 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${prodCfg.configPath}/openwebui 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${prodCfg.configPath}/comfyui 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${prodCfg.configPath}/basedir 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];

    systemd.services = {
      podman-openwebui = {
        after = mkAfter [ "podman-ollama.service" ];
        serviceConfig = {
          RestartSec = "30s";
          StartLimitBurst = 10;
          StartLimitIntervalSec = 600;
        };
      };

      podman-ollama.serviceConfig = {
        RestartSec = "10s";
        StartLimitBurst = 10;
        StartLimitIntervalSec = 600;
      };
      podman-comfyui-nvidia.serviceConfig = {
        RestartSec = "10s";
        StartLimitBurst = 10;
        StartLimitIntervalSec = 600;
      };
    };

    hardware.nvidia-container-toolkit.enable = mkIf config.hardware.nvidia.modesetting.enable true;
  };
}
