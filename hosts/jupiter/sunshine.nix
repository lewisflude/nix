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
    # DP-3: Primary 4K display
    # HDMI-A-4: Dummy output for streaming (always enabled)
    primaryDisplay = "DP-3";
    streamingDisplay = "HDMI-A-4";

    # Lock screen when streaming ends for security
    lockOnStreamEnd = true;

    # Audio sink for streaming (NVIDIA HDMI audio)
    # Find with: pactl list sinks | grep -A 5 "Name:"
    audioSink = "alsa_output.pci-0000_01_00.1.hdmi-stereo";
  };

  # Enable CUDA support for NVENC hardware encoding (RTX 4090)
  # Without this, Sunshine can't load libcuda.so.1 and falls back to software encoding
  # See: https://discourse.nixos.org/t/rtx-3070-sunshine-nvec-encoding-fails/62131
  nixpkgs.config.packageOverrides = super: {
    sunshine = super.sunshine.override { cudaSupport = true; };
  };
}
