# Audio Feature Module - Main Entry Point
# Combines all audio sub-modules into a cohesive configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkMerge;
  cfg = config.host.features.media.audio;
in
{
  imports = [
    ./pipewire.nix
    ./wireplumber.nix
    ./gaming.nix
    ./bluetooth.nix
    ./hdmi.nix
    ./processing.nix
    ./usb.nix
    ./kernel.nix
  ];

  config = mkMerge [
    {
      # Assertions to ensure proper configuration
      assertions = [
        {
          assertion = cfg.noiseCancellation -> cfg.enable;
          message = "Noise cancellation requires audio.enable to be true";
        }
        {
          assertion = cfg.echoCancellation -> cfg.enable;
          message = "Echo cancellation requires audio.enable to be true";
        }
      ];
    }
  ];
}
