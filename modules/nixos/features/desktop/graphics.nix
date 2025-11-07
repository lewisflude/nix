{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;

  # NVIDIA Driver Branch Selection
  # For RTX 4090 (Ada Lovelace architecture), choose the driver that works best:
  # package = config.boot.kernelPackages.nvidiaPackages.stable;      # Alternative: Latest stable release
  package = config.boot.kernelPackages.nvidiaPackages.beta; # ACTIVE: Bleeding edge features (best for 40-series)
  # package = config.boot.kernelPackages.nvidiaPackages.production; # Alternative: Conservative, well-tested (fewer features)
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

      # Uncomment if experiencing cursor glitches/artifacts with NVIDIA + Wayland
      # Forces software cursor rendering instead of hardware cursors
      # WLR_NO_HARDWARE_CURSORS = "1";
    };
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [
          # NVIDIA driver package - provides GBM backend for Wayland compositors
          package
        ]
        ++ (with pkgs; [
          # NVIDIA VA-API bridge for hardware video acceleration
          nvidia-vaapi-driver

          # Wayland EGL support for GPU access from Wayland compositors
          egl-wayland

          # Mesa EGL libraries for general OpenGL/EGL support
          # Note: niri uses the same nixpkgs via flake follows, so Mesa versions stay in sync
          mesa
          libglvnd

          # Vulkan and graphics debugging tools
          vulkan-tools
          mesa-demos # includes glxinfo / eglinfo

          # VA-API (Video Acceleration API) support
          libva # VA-API loader
          libva-utils # vainfo for checking VA-API support

          # NVIDIA codec headers for encoding/decoding
          nv-codec-headers
        ]);
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

        # Driver package selection (see package definition above)
        inherit package;

        # nvidia-patch for stream limits - currently disabled
        # Uncomment to remove NVENC/NVFBC stream limits:
        # package = pkgs.nvidia-patch.patch-nvenc (pkgs.nvidia-patch.patch-fbc package);
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
