# Graphics Configuration
# NVIDIA GPU setup, hardware video acceleration, Wayland environment
_: {
  flake.modules.nixos.graphics =
    { pkgs, config, ... }:
    {
      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true; # Required for Steam/Wine/VR
          extraPackages = [
            pkgs.nvidia-vaapi-driver # Hardware video decode
            pkgs.libva-vdpau-driver # VDPAU backend for VA-API
          ];
        };

        nvidia = {
          modesetting.enable = true; # Required for Wayland
          open = true; # Required for Turing+ (RTX 4090)
          package = config.boot.kernelPackages.nvidiaPackages.production;
        };

        # GPU access in containers (Ollama, etc.)
        nvidia-container-toolkit.enable = true;
      };

      services.xserver.videoDrivers = [ "nvidia" ];

      # NVIDIA GPU is card1
      environment.sessionVariables = {
        WLR_DRM_DEVICES = "/dev/dri/card1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORMTHEME = "gtk2";
        XCURSOR_SIZE = "32";
        XCURSOR_THEME = "phinger-cursors-light";
      };
    };
}
