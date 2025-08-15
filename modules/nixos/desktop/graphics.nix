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
  # Session environment (conservative, stable)
  ########################################
  environment.sessionVariables = {
    # Prefer native Wayland for Electron; fall back to X11 per-app if needed
    ELECTRON_OZONE_PLATFORM_HINT = "auto";

    # NVIDIA VA-API bridge; harmless if a given app doesn’t use it
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    __GL_VRR_ALLOWED = "1";
    __GL_GSYNC_ALLOWED = "1";

    # Historical NVIDIA cursor workaround — start OFF; enable only if you see the classic “cursor trail” bug
    # WLR_NO_HARDWARE_CURSORS = "1";

    # REMOVE the following legacy/fragile knobs:
    # WLR_RENDERER_ALLOW_SOFTWARE
    # WLR_BACKENDS
    # GBM_BACKEND
    # __GLX_VENDOR_LIBRARY_NAME (not needed outside X11)
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
      open = false; # flip to true if you want the open kernel module and it’s stable for you
      nvidiaSettings = true;
      inherit package;
      powerManagement.enable = true;
      nvidiaPersistenced = true;
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
