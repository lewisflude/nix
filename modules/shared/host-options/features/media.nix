# Media Production Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  media = {
    enable = mkEnableOption "media production tools and environments" // {
      default = false;
      example = true;
    };

    audio = {
      enable = mkEnableOption "audio production and music" // {
        example = true;
      };
      production = mkEnableOption "DAW and audio tools" // {
        example = true;
      };
      realtime = mkEnableOption "real-time audio optimizations (musnix)" // {
        example = true;
      };

      # Low-latency settings for professional audio work
      ultraLowLatency = mkOption {
        type = types.bool;
        default = false;
        description = "Enable ultra-low latency settings (64 frames @ 48kHz = ~1.3ms) for professional recording";
        example = true;
      };

      # USB audio interface optimization
      usbAudioInterface = {
        enable =
          mkEnableOption "USB audio interface optimizations (disable autosuspend, set IRQ priorities)"
          // {
            example = true;
          };

        # PCI ID of the USB controller (not the audio device itself)
        # Find with: lspci | grep -i usb
        # Example: "00:14.0" for Intel xHCI controller
        pciId = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "PCI ID of the USB controller for latency timer optimization";
          example = "00:14.0";
        };
      };

      # musnix advanced options
      rtirq = mkOption {
        type = types.bool;
        default = true;
        description = "Enable rtirq for IRQ priority management (requires realtime kernel)";
        example = true;
      };

      dasWatchdog = mkOption {
        type = types.bool;
        default = true;
        description = "Enable das_watchdog to prevent RT processes from hanging the system";
        example = true;
      };

      rtcqs = mkOption {
        type = types.bool;
        default = true;
        description = "Install rtcqs (realtime configuration quick scan) analysis tool";
        example = true;
      };

      noiseCancellation = mkOption {
        type = types.bool;
        default = false;
        description = "Enable RNNoise-based noise cancellation filter (for voice chat/calls)";
        example = true;
      };

      echoCancellation = mkOption {
        type = types.bool;
        default = false;
        description = "Enable WebRTC-based echo cancellation (for voice chat/calls)";
        example = true;
      };

      audioNix = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable audio packages from polygon/audio.nix flake";
          example = true;
        };

        bitwig = mkOption {
          type = types.bool;
          default = false;
          description = "Install Bitwig Studio (latest beta version)";
          example = true;
        };

        plugins = mkOption {
          type = types.bool;
          default = false;
          description = "Install audio plugins from audio.nix (neuralnote, paulxstretch, etc.)";
          example = true;
        };
      };
    };

    video = {
      enable = mkEnableOption "video production and editing tools" // {
        example = true;
      };

      editing = mkEnableOption "video editing tools (kdenlive, ffmpeg, handbrake, imagemagick, gimp)" // {
        example = true;
      };

      streaming = mkEnableOption "video streaming tools (v4l2loopback for virtual camera)" // {
        example = true;
      };
    };

    streaming = {
      enable = mkEnableOption "media streaming and recording (OBS Studio)" // {
        example = true;
      };
    };
  };
}
