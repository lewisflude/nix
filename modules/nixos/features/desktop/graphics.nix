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
    # NVIDIA-specific environment variables for Wayland support
    # These are NOT set automatically by hardware.nvidia module
    environment.sessionVariables = {
      # NVIDIA GBM backend - required for Wayland compositors
      # Without this, Wayland compositors will try to use Mesa's GBM
      GBM_BACKEND = "nvidia-drm";

      # Tell libglvnd to use NVIDIA's EGL/OpenGL implementation
      # This ensures NVIDIA's EGL extensions are available
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";

      # NVIDIA VA-API (video acceleration) support
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
    };
    hardware = {
      graphics = {
        enable = true;
        # enable32Bit is now controlled by gaming feature
        # Only enable if gaming is enabled (set in gaming.nix)
        enable32Bit = config.host.features.gaming.enable or false;
        extraPackages = [
          # NVIDIA driver package - provides GBM backend for Wayland compositors
          package

          # NVIDIA VA-API bridge for hardware video acceleration
          pkgs.nvidia-vaapi-driver

          # Wayland EGL support for GPU access from Wayland compositors
          pkgs.egl-wayland

          # Mesa EGL libraries for general OpenGL/EGL support
          # Note: niri uses the same nixpkgs via flake follows, so Mesa versions stay in sync
          pkgs.mesa
          pkgs.libglvnd

          # Vulkan and graphics debugging tools
          pkgs.vulkan-tools
          pkgs.mesa-demos # includes glxinfo / eglinfo

          # VA-API (Video Acceleration API) support
          pkgs.libva # VA-API loader
          pkgs.libva-utils # vainfo for checking VA-API support

          # NVIDIA codec headers for encoding/decoding
          pkgs.nv-codec-headers
        ];
      };
      nvidia = {
        # DRM kernel modesetting - REQUIRED for Wayland compositors
        # Also set via boot.kernelParams in boot.nix: nvidia-drm.modeset=1
        modesetting.enable = true;

        # Open-source kernel modules - REQUIRED for RTX 4090 (Ada Lovelace)
        # Provides EGL_EXT_device_drm extension needed by niri and other Wayland compositors
        # Open modules are mandatory for 40-series GPUs and recommended for 20/30-series
        open = true;

        # NVIDIA Settings GUI for GPU configuration
        nvidiaSettings = true;

        # Power management settings
        powerManagement = {
          enable = true;
          finegrained = false; # For desktop use; set to true for laptops with hybrid graphics
        };

        # Persistence daemon - keep disabled unless experiencing state issues
        nvidiaPersistenced = false;

        # Composition pipeline - keep disabled for Wayland (X11 feature)
        forceFullCompositionPipeline = false;

        # PRIME offload - not needed for desktop with single GPU
        prime.offload.enableOffloadCmd = false;

        inherit package;
      };
      nvidia-container-toolkit.enable = true;
    };
    # Note: services.xserver must be enabled even for Wayland-only setups
    # The NVIDIA module requires this to properly set up graphics drivers
    services.xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };
    services.udev.extraRules = ''
      ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk system create-dev-char-symlinks --create-all"
      KERNEL=="card[0-9]*", SUBSYSTEM=="drm", ACTION=="change", RUN+="${pkgs.bash}/bin/bash -c 'echo detect > /sys/class/drm/card1-DP-1/status'"
    '';
    boot.blacklistedKernelModules = [ "nouveau" ];
  };
}
