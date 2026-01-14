# Monado OpenXR Runtime Configuration
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
in
lib.mkIf cfg.enable {
  services.monado = lib.mkIf cfg.monado {
    enable = true;
    defaultRuntime = !cfg.wivrn.enable || !cfg.wivrn.defaultRuntime;
    highPriority = cfg.performance; # Enable high priority for better frame timing
  };

  # Monado systemd service environment variables for performance and lifecycle
  # Only add these when monado is explicitly enabled (not when WiVRn manages it)
  # Managed via systemd user service: systemctl --user start/stop monado
  # Automatically starts via monado.socket when OpenXR apps connect
  systemd.user.services.monado = lib.mkIf cfg.monado {
    environment = {
      # Auto-stop Monado when all XR applications disconnect
      # Reduces resource usage when VR is not in active use
      IPC_EXIT_ON_DISCONNECT = "1";

      # Performance optimization: Minimum compositor frame time in milliseconds
      # Lower values reduce latency but increase CPU usage
      # Adjust as needed for headset view stuttering (try values: 3-10)
      # Default: 5ms for Quest 3 high-refresh-rate support (90Hz/120Hz)
      U_PACING_COMP_MIN_TIME_MS = "5";
    };
  };

  # Required packages for OpenXR to work correctly
  environment.systemPackages = [
    pkgs.openxr-loader
    pkgs.vulkan-loader
    pkgs.libglvnd # Provides libGL
    pkgs.xorg.libX11
  ];
}
