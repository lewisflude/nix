{
  config,
  pkgs,
  ...
}: let
  package = config.boot.kernelPackages.nvidiaPackages.beta;
in {
  environment.sessionVariables = {
    __GL_SYNC_DISPLAY_DEVICE = "DP-1";
    __GL_SYNC_TO_VBLANK = "1";
  };
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
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
    videoDrivers = ["nvidia"];
  };
  services.udev.extraRules = ''
    ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk system create-dev-char-symlinks --create-all"
    KERNEL=="card[0-9]*", SUBSYSTEM=="drm", ACTION=="change", RUN+="${pkgs.bash}/bin/bash -c 'echo detect > /sys/class/drm/card1-DP-1/status'"
  '';
  boot.blacklistedKernelModules = ["nouveau"];
}
