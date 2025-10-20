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
        # NOTE: This is the legacy container version. Prefer native NixOS service:
        # host.features.aiTools.enable = true;
        ollama = {
          # Pinned version for reproducibility
          image = "ollama/ollama:0.1.48";

          environment = {
            OLLAMA_KEEP_ALIVE = "24h";
            # Set home directory to avoid /root mount
            HOME = "/data";
          };

          # Use /data instead of /root for better container practices
          volumes = ["${prodCfg.configPath}/ollama:/data/.ollama"];

          extraOptions = [
            "--network=host"
            "--device=nvidia.com/gpu=all"

            # Resource limits
            "--memory=16g"
            "--cpus=8"
          ];
        };

        # Open WebUI - Web interface for LLMs
        # NOTE: This is the legacy container version. Prefer native NixOS service:
        # host.features.aiTools.openWebui.enable = true;
        openwebui = {
          # Pinned version for reproducibility
          image = "ghcr.io/open-webui/open-webui:0.3.13-cuda";

          environment = {
            TZ = cfg.timezone;
            OLLAMA_BASE_URL = "http://localhost:11434";
          };

          volumes = ["${prodCfg.configPath}/openwebui:/app/backend/data"];
          ports = ["7000:8080"];

          extraOptions = [
            "--device=nvidia.com/gpu=all"

            # Resource limits
            "--memory=8g"
            "--cpus=4"
          ];

          # Soft dependency - don't fail if ollama is down
          # dependsOn removed - using After= via systemd overrides
        };

        # ComfyUI - AI image generation
        # NOTE: Consider migrating to containers-supplemental module
        comfyui-nvidia = {
          # Pinned version for reproducibility
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

          ports = ["8188:8188"];

          extraOptions = [
            "--device=nvidia.com/gpu=all"

            # Resource limits (GPU workloads need more resources)
            "--memory=16g"
            "--memory-swap=20g"
            "--cpus=8"
          ];
        };
      }
      // (mkIf prodCfg.enableCup {
        # CUP - Container Update Proxy
        # WARNING: This container has full access to podman.sock (security risk)
        # Only enable if you understand the implications
        cup = {
          # Pinned version for security
          image = "ghcr.io/sergi0g/cup:v1.2.0";

          cmd = ["serve" "-p" "1188"];

          volumes = [
            # SECURITY WARNING: Full access to container runtime
            "/run/podman/podman.sock:/var/run/docker.sock"
          ];

          extraOptions = [
            "--network=host"

            # Resource limits
            "--memory=256m"
            "--cpus=0.5"
          ];
        };
      });

    # Create necessary directories for productivity stack
    systemd.tmpfiles.rules = [
      "d ${prodCfg.configPath}/ollama 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${prodCfg.configPath}/openwebui 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${prodCfg.configPath}/comfyui 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${prodCfg.configPath}/basedir 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];

    # Override service dependencies to use soft After= instead of hard Requires=
    systemd.services = {
      podman-openwebui = {
        after = mkAfter ["podman-ollama.service"];
        serviceConfig = {
          RestartSec = "30s";
          StartLimitBurst = 10;
          StartLimitIntervalSec = 600;
        };
      };
      # Make base services more resilient
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

    # Ensure GPU support for productivity containers
    hardware.nvidia-container-toolkit.enable = mkIf config.hardware.nvidia.modesetting.enable true;
  };
}
