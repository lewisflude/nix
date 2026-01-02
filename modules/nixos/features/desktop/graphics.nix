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

      # Wayland/GBM backend support
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";

      # Gaming optimizations (shader caching and threading)
      __GL_SHADER_DISK_CACHE = "1";
      __GL_THREADED_OPTIMIZATION = "1";

      # HDR (High Dynamic Range) support
      # HDR is automatically enabled by Niri if the display and GPU support it
      # Requires kernel 6.2+ with DRM HDR support (enabled by default)
      # Monitor: AW3423DWF supports HDR10
      # GPU: RTX 4090 supports HDR
      # Applications: Gamescope supports HDR (gamescope-wsi package installed)
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
        open = true; # Open-source kernel modules for RTX 4090 (Turing+)
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
      ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN += "${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk system create-dev-char-symlinks --create-all"

      # Ensure displays stay active for Sunshine KMS capture
      # Only write "detect" if status is disconnected (avoids unnecessary writes)
      # This reduces system load and prevents interference with input devices
      KERNEL=="card[0-9]*", SUBSYSTEM=="drm", ACTION=="change", RUN += "${pkgs.bash}/bin/bash -c 'status_file=/sys/class/drm/card1-DP-3/status; [ -f \"$$status_file\" ] && [ \"$$(cat \"$$status_file\" 2>/dev/null)\" = \"disconnected\" ] && echo detect > \"$$status_file\" 2>/dev/null || true'"
      KERNEL=="card[0-9]*", SUBSYSTEM=="drm", ACTION=="change", RUN += "${pkgs.bash}/bin/bash -c 'status_file=/sys/class/drm/card1-HDMI-A-4/status; [ -f \"$$status_file\" ] && [ \"$$(cat \"$$status_file\" 2>/dev/null)\" = \"disconnected\" ] && echo detect > \"$$status_file\" 2>/dev/null || true'"
    '';

    boot.blacklistedKernelModules = [ "nouveau" ];
  };
}
