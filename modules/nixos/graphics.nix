{ config
, pkgs
, inputs ? {}
, lib
, ...
}:
let
  package = config.boot.kernelPackages.nvidiaPackages.beta;
  pkgs-unstable = if (inputs ? hyprland && inputs.hyprland ? inputs && inputs.hyprland.inputs ? nixpkgs)
    then inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}
    else pkgs;
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
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    NIXOS_OZONE_WL = "1";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "0";

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
