# Productivity Stack
# Converts services from /opt/stacks/productivity
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.containers;
  prodCfg = cfg.productivity;
in {
  config = mkIf (cfg.enable && prodCfg.enable) {
    virtualisation.oci-containers.containers =
      {
        # Ollama - LLM backend
        ollama = {
          image = "ollama/ollama:latest";
          environment = {
            OLLAMA_KEEP_ALIVE = "24h";
          };
          volumes = ["${prodCfg.configPath}/ollama:/root/.ollama"];
          extraOptions = [
            "--network=host"
            "--device=nvidia.com/gpu=all"
          ];
        };

        # Open WebUI - Web interface for LLMs
        openwebui = {
          image = "ghcr.io/open-webui/open-webui:dev-cuda";
          environment = {
            TZ = cfg.timezone;
          };
          volumes = ["${prodCfg.configPath}/openwebui:/app/backend/data"];
          ports = ["7000:8080"];
          extraOptions = [
            "--device=nvidia.com/gpu=all"
          ];
          dependsOn = ["ollama"];
        };

        # ComfyUI - AI image generation
        comfyui-nvidia = {
          image = "mmartial/comfyui-nvidia-docker:latest";
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
          ports = ["8188:8188"];
          extraOptions = [
            "--device=nvidia.com/gpu=all"
          ];
        };
      }
      // (mkIf prodCfg.enableCup {
        # CUP - Container Update Proxy (disabled by default due to full podman.sock access)
        cup = {
          image = "ghcr.io/sergi0g/cup:latest";
          cmd = ["serve" "-p" "1188"];
          volumes = ["/run/podman/podman.sock:/var/run/docker.sock"];
          extraOptions = ["--network=host"];
        };
      });

    # Create necessary directories for productivity stack
    systemd.tmpfiles.rules = [
      "d ${prodCfg.configPath}/ollama 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${prodCfg.configPath}/openwebui 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${prodCfg.configPath}/comfyui 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${prodCfg.configPath}/basedir 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];

    # Ensure GPU support for productivity containers
    hardware.nvidia-container-toolkit.enable = mkIf config.hardware.nvidia.modesetting.enable true;
  };
}
