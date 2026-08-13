# Graphics Configuration
# NVIDIA GPU setup, hardware video acceleration, Wayland environment
_: {
  flake.modules.nixos.graphics =
    { pkgs, config, ... }:
    {
      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true; # Required for Steam/Wine/VR
          extraPackages = [
            pkgs.nvidia-vaapi-driver # Hardware video decode
            pkgs.libva-vdpau-driver # VDPAU backend for VA-API
          ];
        };

        nvidia = {
          modesetting.enable = true; # Required for Wayland
          open = true; # Required for Turing+ (RTX 4090)
          # `production` (595.91.07), not `latest` (610.57.04). The 2026-08-12
          # shutdown-phase kernel NULL deref fired after /mnt/storage and /home
          # had already unmounted cleanly — a device-teardown window, not a
          # filesystem one — with nvidia_drm at 111 refs. nvidia_drm unload
          # NULL derefs are a recurring family on bleeding-edge branches, and
          # `latest` is a very new driver against a pinned 6.12 LTS kernel.
          package = config.boot.kernelPackages.nvidiaPackages.production;
        };

        # GPU access in containers (Ollama, etc.)
        nvidia-container-toolkit.enable = true;
      };

      services.xserver.videoDrivers = [ "nvidia" ];

      # NVIDIA modprobe: PAT for better memory mapping, ReBAR for faster CPU-GPU transfers
      boot.extraModprobeConfig = ''
        options nvidia NVreg_UsePageAttributeTable=1
        options nvidia NVreg_EnableResizableBar=1
      '';

      # NVIDIA GPU is card1
      environment.sessionVariables = {
        WLR_DRM_DEVICES = "/dev/dri/card1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        NIXOS_OZONE_WL = "1";
      };
    };
}
