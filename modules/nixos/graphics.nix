{
  config,
  pkgs,
  ...
}:
let
  package = config.boot.kernelPackages.nvidiaPackages.beta;
in
{

  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver
    egl-wayland
    nv-codec-headers
    cudaPackages.cuda_nvcc
    vulkan-tools
    mesa
    libGL
    libglvnd
    mesa-demos
  ];
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    WLR_BACKENDS = "headless,drm,wayland";

    # NVIDIA EGL/Wayland support
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    __GL_VRR_ALLOWED = "0";
  };
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
        mesa
        libGL
        libglvnd
      ];
    };
    nvidia-container-toolkit = {
      enable = true;
    };
    nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
      package = package;
    };
  };
  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };
    udev.extraRules = ''
      ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk system create-dev-char-symlinks --create-all"
    '';
  };
  boot.blacklistedKernelModules = [ "nouveau" ];
}
