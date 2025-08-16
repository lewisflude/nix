{
  config,
  pkgs,
  ...
}: let
  package = config.boot.kernelPackages.nvidiaPackages.stable;
in {
  ########################################
  # Packages and tools
  ########################################
  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos # glxinfo / eglinfo
    libva # VA-API loader
    libva-utils # vainfo
    egl-wayland
    nv-codec-headers
    # cudaPackages.cuda_nvcc # keep only if you actually build CUDA locally
  ];

  ########################################
  # Session environment (optimized for RTX 4090 + Wayland gaming/work)
  ########################################
  environment.sessionVariables = {
    # NVIDIA optimization for Wayland
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";

    # VRR/G-SYNC support for RTX 4090 (excellent support)
    __GL_VRR_ALLOWED = "1";
    __GL_GSYNC_ALLOWED = "1";

    # Gaming performance optimizations
    __GL_SHADER_DISK_CACHE = "1";
    __GL_THREADED_OPTIMIZATIONS = "1";

    # RTX 4090 specific optimizations
    __GL_SYNC_TO_VBLANK = "0"; # Let VRR/compositor handle this
    __GL_ALLOW_UNOFFICIAL_PROTOCOL = "1";

    # NVIDIA cursor fix (uncomment if you see cursor trails)
    # WLR_NO_HARDWARE_CURSORS = "1";
  };

  ########################################
  # Graphics stack
  ########################################
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true; # set false unless you need 32-bit (Steam/Proton, some games)
      # Keep this clean: mesa drivers come via hardware.graphics; avoid extra shim layers
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        # Avoid these for NVIDIA + VA-API bridge:
        # vaapiVdpau
        # libvdpau-va-gl
      ];
    };

    nvidia = {
      modesetting.enable = true; # required for Wayland/GBM
      open = false; # RTX 4090 works well with proprietary drivers
      nvidiaSettings = true;
      inherit package;

      # Power management optimizations for RTX 4090
      powerManagement = {
        enable = true;
        finegrained = false; # RTX 4090 doesn't need fine-grained power management
      };

      # Keep GPU state persistent for better performance
      nvidiaPersistenced = true;

      # RTX 4090 performance optimizations
      forceFullCompositionPipeline = false; # Let VRR handle frame pacing
      prime.offload.enableOffloadCmd = false; # RTX 4090 is primary GPU
    };

    nvidia-container-toolkit.enable = true;
  };

  ########################################
  # X11 / XWayland
  ########################################
  services.xserver = {
    enable = false; # don’t start a full X server on Wayland
    videoDrivers = ["nvidia"];
  };

  ########################################
  # Udev helper for nvidia-container-toolkit
  ########################################
  services.udev.extraRules = ''
    ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk system create-dev-char-symlinks --create-all"
  '';

  ########################################
  # Kernel module blacklist
  ########################################
  boot.blacklistedKernelModules = ["nouveau"];
}
