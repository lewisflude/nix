# HDMI Audio Device Configuration
# NVIDIA and Intel HDMI audio optimization for streaming
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.media.audio;
in
{
  config = mkIf cfg.enable {
    services.pipewire.wireplumber.extraConfig = {
      # Configure HDMI audio devices
      # NVIDIA HDMI is enabled for Sunshine streaming with optimized settings
      # Intel PCH is set to very low priority as a backup (but not disabled)
      "10-hdmi-audio-config" = {
        # Device-level rules (for cards)
        "monitor.alsa.rules" = [
          {
            # Enable NVIDIA HDMI audio device
            matches = [
              { "device.name" = "~alsa_card.pci-0000_01_00.1"; } # NVIDIA AD102 High Definition Audio Controller
            ];
            actions.update-props = {
              "device.disabled" = false; # Explicitly enable (was disabled before)
              "priority.session" = 30; # Lower than Apogee (100) but higher than Intel (10)
            };
          }
          {
            # Set Intel PCH to low priority (kept as backup fallback)
            matches = [
              { "device.name" = "~alsa_card.pci-0000_00_1f.3"; } # Intel PCH Built-in Audio
            ];
            actions.update-props = {
              "priority.session" = 10;
            };
          }
        ];

        # Node-level rules (for actual audio streams)
        "monitor.rules" = [
          {
            # Configure NVIDIA HDMI output node for low-latency streaming
            matches = [
              { "node.name" = "~alsa_output.pci-0000_01_00.1.*"; }
            ];
            actions.update-props = {
              "audio.format" = "S16LE"; # Force 16-bit (hardware native format)
              "audio.rate" = 48000;
              "audio.channels" = 2;
              "audio.position" = "FL,FR";
              "api.alsa.period-size" = 256; # Reduce from 1024 for lower latency
              "api.alsa.period-num" = 2; # Reduce from 32 for lower latency
              "api.alsa.headroom" = 0;
              "session.suspend-timeout-seconds" = 0; # Never suspend during streaming
            };
          }
        ];
      };
    };
  };
}
