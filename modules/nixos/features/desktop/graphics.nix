{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;
  # Use the latest stable production driver for the 4090 to avoid RT kernel segfaults
  # Real-time kernels use a strict interrupt model that NVIDIA's beta drivers
  # (like 590.x) can't always handle. The stable branch (565/570) has much better
  # "Bar Mapping" stability and RT kernel compatibility.
  nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.stable;
in
{
  config = lib.mkIf cfg.enable {
    hardware = {
      graphics = {
        enable = true;
        # 32-bit support is now global for desktop - needed for almost all games/VR
        # Previously conditional on gaming.enable, but VR and Steam both require it
        enable32Bit = true;
        extraPackages = [
          pkgs.nvidia-vaapi-driver
          pkgs.egl-wayland
          pkgs.libva-utils
          pkgs.vulkan-tools
        ];
      };

      nvidia = {
        modesetting.enable = true;
        open = true; # Correct for 4090 (Turing+)
        package = nvidiaPackage;
        nvidiaSettings = true;
        powerManagement.enable = false; # Not needed for desktop gaming GPUs
      };

      # NVIDIA Container Toolkit - Required for Podman GPU acceleration
      # Enables GPU access in containers for AI workloads (Ollama, etc.)
      nvidia-container-toolkit.enable = true;
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    # Explicit nouveau blacklist to prevent race conditions during boot
    # While nvidia-utils blacklists nouveau by default, explicit blacklisting
    # is still recommended to prevent the nouveau driver from loading before nvidia
    boot.blacklistedKernelModules = [ "nouveau" ];

    environment.sessionVariables = lib.mkMerge [
      # NVIDIA-specific configuration
      {
        # Force NVIDIA GPU (card2) for Wayland/Niri
        # card1: Intel iGPU (no monitors connected)
        # card2: NVIDIA RTX 4090 (monitors connected here)
        WLR_DRM_DEVICES = "/dev/dri/card2";

        # Hardware video acceleration via nvidia-vaapi-driver
        LIBVA_DRIVER_NAME = "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";

        # Fix Gamescope segfaults on NVIDIA
        NVD_BACKEND = "direct";

        # Note: Shader caching (__GL_SHADER_DISK_CACHE) is enabled by default
        # for non-root users, so explicit setting is unnecessary.
        # Threaded optimizations (__GL_THREADED_OPTIMIZATION) should be set
        # per-application, not system-wide, for best compatibility.
      }

      # Vulkan configuration - conditional on NVIDIA being enabled
      (lib.mkIf config.hardware.nvidia.modesetting.enable {
        # Explicit Vulkan ICD path prevents GPU detection failures in Steam's pressure-vessel container
        # /run/opengl-driver is NixOS's standard dynamically-managed location for graphics drivers
        VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";

        # Disable validation layers for production gaming (significant performance impact)
        # Validation layers can cause 90-95% performance drops in some configurations
        VK_INSTANCE_LAYERS = "";
      })
    ];

    # Udev rule to simplify device permissions for Sunshine/Steam
    services.udev.extraRules = ''
      KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
    '';
  };
}
