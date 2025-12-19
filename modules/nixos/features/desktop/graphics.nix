{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;

  package = config.boot.kernelPackages.nvidiaPackages.beta;
in
{
  config = lib.mkIf cfg.enable {
    # Minimal environment variables for NVIDIA Wayland support
    environment.sessionVariables = {
      # Hardware video acceleration via nvidia-vaapi-driver
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";

      # Gaming optimizations (shader caching and threading)
      __GL_SHADER_DISK_CACHE = "1";
      __GL_THREADED_OPTIMIZATION = "1";
    };

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = config.host.features.gaming.enable or false;
        extraPackages = [
          package
          pkgs.nvidia-vaapi-driver
          pkgs.egl-wayland

          # Debugging and validation tools
          pkgs.vulkan-tools # vulkaninfo, vkcube for testing Vulkan
          pkgs.libva-utils # vainfo for checking video acceleration
        ];
      };

      nvidia = {
        modesetting.enable = true;
        open = false; # Proprietary driver for better gaming performance
        nvidiaSettings = true;
        powerManagement.enable = false; # Not needed for desktop gaming GPUs

        inherit package;
      };

      nvidia-container-toolkit.enable = true;
    };

    services.xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };

    services.udev.extraRules = ''
      ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk system create-dev-char-symlinks --create-all"
      KERNEL=="card[0-9]*", SUBSYSTEM=="drm", ACTION=="change", RUN+="${pkgs.bash}/bin/bash -c 'echo detect > /sys/class/drm/card1-DP-3/status'"
    '';

    boot.blacklistedKernelModules = [ "nouveau" ];
  };
}
