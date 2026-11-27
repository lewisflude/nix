# Graphics Configuration
# NVIDIA GPU setup, hardware video acceleration, Wayland environment
_: {
  flake.modules.nixos.graphics = {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true; # Required for Steam/Wine/VR
        # nvidia-vaapi-driver is added by hardware.nvidia.videoAcceleration
        # (default true).
      };

      nvidia = {
        modesetting.enable = true; # Required for Wayland
        open = true; # Required for Turing+ (RTX 4090)
        # `production` (595.x), not `latest` (610.57.04). The 2026-08-12
        # shutdown-phase kernel NULL deref fired after /mnt/storage and /home
        # had already unmounted cleanly — a device-teardown window, not a
        # filesystem one — with nvidia_drm at 111 refs. nvidia_drm unload
        # NULL derefs are a recurring family on bleeding-edge branches, and
        # `latest` is a very new driver against a pinned 6.12 LTS kernel.
        branch = "production";

        # PAT for better memory mapping, ReBAR for faster CPU-GPU transfers.
        # nvidia-drm.modeset/fbdev are set by the module from
        # modesetting.enable.
        moduleParams.nvidia = {
          NVreg_UsePageAttributeTable = 1;
          NVreg_EnableResizableBar = 1;
        };
      };

      # GPU access in containers (Ollama, etc.)
      nvidia-container-toolkit.enable = true;
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    # niri selects the GPU via debug.render-drm-device (modules/niri/session.nix).
    environment.sessionVariables = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      NIXOS_OZONE_WL = "1";
    };
  };
}
