{
  # deadnix: skip
  config,
  # deadnix: skip
  lib,
  # deadnix: skip
  pkgs,
  ...
}:
{
  # Sunshine streaming configuration for Jupiter gaming PC
  services.sunshine = {
    enable = true;

    # Display configuration for streaming
    # DP-3: Primary 4K display (disabled during streaming)
    # HDMI-A-4: Dummy output for streaming (always enabled)
    display = {
      primary = "DP-3";
      streaming = "HDMI-A-4";
    };

    # Behavior settings
    behavior = {
      lockOnStreamEnd = true; # Lock screen when streaming ends for security
      autoFocusSteam = true; # Focus Steam window after launch
    };

    # Audio configuration
    # Games route to Sunshine's virtual sink (sink-sunshine-stereo)
    # Sunshine captures from its own virtual sink and streams to client
    audio = {
      sink = null; # Use default sink
    };
  };

  # Enable CUDA support for NVENC hardware encoding (RTX 4090)
  # Without this, Sunshine can't load libcuda.so.1 and falls back to software encoding
  # See: https://discourse.nixos.org/t/rtx-3070-sunshine-nvec-encoding-fails/62131
  nixpkgs.config.packageOverrides = super: {
    sunshine = super.sunshine.override { cudaSupport = true; };
  };
}
