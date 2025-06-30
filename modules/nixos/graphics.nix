{
  config,
  pkgs,
  inputs,
  ...
}:
let
  package = config.boot.kernelPackages.nvidiaPackages.beta;
  pkgs-unstable = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{

  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver
    egl-wayland
    nv-codec-headers
    cudaPackages.cuda_nvcc
    vulkan-tools
  ];
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    WLR_BACKENDS = "headless,drm,wayland";

  };
  hardware = {
    graphics = {
      enable = true;
      package = pkgs-unstable.mesa;
      package32 = pkgs-unstable.pkgsi686Linux.mesa;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
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
