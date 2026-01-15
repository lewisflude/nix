{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{
  config = lib.mkIf cfg.enable {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true; # Required for Steam/Wine/VR
        extraPackages = [
          pkgs.nvidia-vaapi-driver # Hardware video decode
          pkgs.libva-vdpau-driver # Required for Immersed VR
        ];
      };

      nvidia = {
        modesetting.enable = true; # Required for Wayland
        open = true; # Required for Turing+ (RTX 4090)
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      # GPU access in containers (Ollama, etc.)
      nvidia-container-toolkit.enable = true;
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    # Host-specific: NVIDIA GPU is card2 (Intel iGPU is card1, no monitors)
    environment.sessionVariables = {
      WLR_DRM_DEVICES = "/dev/dri/card2";
      # Enable Wayland for Electron/Chromium apps system-wide
      NIXOS_OZONE_WL = "1";
    };
  };
}
