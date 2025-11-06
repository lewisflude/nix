{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
in
{
  config = lib.mkIf cfg.enable {
    environment.sessionVariables = {
      # Display synchronization (reduce tearing)
      __GL_SYNC_DISPLAY_DEVICE = "DP-1";
      __GL_SYNC_TO_VBLANK = "1";

      # Wayland support for Electron/Chromium apps
      ELECTRON_OZONE_PLATFORM_HINT = "auto";

      # NVIDIA VA-API (video acceleration) support
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
    };
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          # NVIDIA VA-API bridge for hardware video acceleration
          nvidia-vaapi-driver

          # Wayland EGL support for GPU access from Wayland compositors
          egl-wayland

          # Vulkan and graphics debugging tools
          vulkan-tools
          mesa-demos # includes glxinfo / eglinfo

          # VA-API (Video Acceleration API) support
          libva # VA-API loader
          libva-utils # vainfo for checking VA-API support

          # NVIDIA codec headers for encoding/decoding
          nv-codec-headers
        ];
      };
      nvidia = {
        modesetting.enable = true;
        open = false;
        nvidiaSettings = true;
        inherit package;
        powerManagement = {
          enable = true;
          finegrained = false;
        };
        nvidiaPersistenced = false;
        forceFullCompositionPipeline = false;
        prime.offload.enableOffloadCmd = false;
      };
      nvidia-container-toolkit.enable = true;
    };
    services.xserver = {
      enable = false;
      videoDrivers = [ "nvidia" ];
    };
    services.udev.extraRules = ''
      ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk system create-dev-char-symlinks --create-all"
      KERNEL=="card[0-9]*", SUBSYSTEM=="drm", ACTION=="change", RUN+="${pkgs.bash}/bin/bash -c 'echo detect > /sys/class/drm/card1-DP-1/status'"
    '';
    boot.blacklistedKernelModules = [ "nouveau" ];
  };
}
