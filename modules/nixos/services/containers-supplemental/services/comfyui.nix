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
    mkMerge
    ;
  containersLib = import ../lib.nix { inherit lib; };
  inherit (containersLib) mkResourceOptions mkResourceFlags;
  cfg = config.host.services.containersSupplemental;
in
{
  options.host.services.containersSupplemental.comfyui = {
    enable = mkEnableOption "ComfyUI NVIDIA container" // {
      default = false;
    };

    image = mkOption {
      type = types.str;
      default = "docker.io/runpod/comfyui:latest";
      description = ''
        Container image reference for ComfyUI with NVIDIA GPU support.
        Must provide CUDA-enabled runtime and include the ComfyUI entrypoint.
      '';
      example = "docker.io/runpod/comfyui:latest";
    };

    dataPath = mkOption {
      type = types.str;
      default = "/var/lib/containers/supplemental/comfyui";
      description = "Path for ComfyUI data.";
    };

    resources = mkResourceOptions {
      memory = "16g";
      cpus = "8";
      memorySwap = "20g";
    };
  };

  config = mkIf (cfg.enable && cfg.comfyui.enable) (mkMerge [
    {
      virtualisation.oci-containers.containers."comfyui-nvidia" = {
        inherit (cfg.comfyui) image;
        environment = {
          WANTED_UID = toString cfg.uid;
          WANTED_GID = toString cfg.gid;
          BASE_DIRECTORY = "/basedir";
          SECURITY_LEVEL = "normal";
          NVIDIA_VISIBLE_DEVICES = "all";
          NVIDIA_DRIVER_CAPABILITIES = "all";
        };
        volumes = [
          "${cfg.comfyui.dataPath}/comfyui:/comfy/mnt"
          "${cfg.comfyui.dataPath}/basedir:/basedir"
        ];
        ports = [ "8188:8188" ];
        extraOptions = [
          "--device=nvidia.com/gpu=all"
        ]
        ++ mkResourceFlags cfg.comfyui.resources;
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.comfyui.dataPath}/comfyui 0755 ${toString cfg.uid} ${toString cfg.gid} -"
        "d ${cfg.comfyui.dataPath}/basedir 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ];

      systemd.services.podman-comfyui-nvidia = {
        wants = [ "systemd-tmpfiles-setup.service" ];
        after = [ "systemd-tmpfiles-setup.service" ];
        preStart = ''
          install -d -m 0755 -o ${toString cfg.uid} -g ${toString cfg.gid} \
            ${cfg.comfyui.dataPath}/comfyui \
            ${cfg.comfyui.dataPath}/basedir
        '';
      };
    }
    (mkIf (config.hardware.nvidia.modesetting.enable or false) {
      hardware.nvidia-container-toolkit.enable = true;
    })
  ]);
}
