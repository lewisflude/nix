# Media Production feature module (cross-platform)
# Controlled by host.features.media.*
# Provides comprehensive media production tools: audio, video, and streaming
{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
with lib; let
  cfg = config.host.features.media;
  platformLib = (import ../../../../lib/functions.nix {inherit lib;}).withSystem hostSystem;
  isLinux = platformLib.isLinux;
  isDarwin = platformLib.isDarwin;
  audioNixCfg = cfg.audio.audioNix;
in {
  config = mkIf cfg.enable {
    # System-level packages (NixOS only)
    environment.systemPackages = mkIf isLinux (
      with pkgs;
        [
          # Audio production packages
        ]
        # Standard audio production packages
        ++ optionals (cfg.audio.enable && cfg.audio.production) [
          audacity
          helm # Software synthesizer
          lsp-plugins # Linux Studio Plugins
        ]
        # Audio.nix packages (from polygon/audio.nix flake via overlay)
        # These packages are available through the audio-nix overlay in overlays/default.nix
        ++ optionals (cfg.audio.enable && audioNixCfg.enable) (
          # Bitwig Studio (use stable version for better compatibility)
          (optional audioNixCfg.bitwig bitwig-studio-stable-latest)
          # Audio plugins from audio.nix
          ++ (optionals audioNixCfg.plugins [
            # Working packages - tested individually
            neuralnote # AI-powered audio transcription ✓
            paulxstretch # Extreme audio time-stretching ✓

            # Note: CHOW plugins and synths require gcc11Stdenv which has been
            # removed from nixpkgs-unstable. These will work once audio.nix is
            # updated to use gcc13Stdenv or later.
            #
            # To use these packages now, you can:
            # 1. Run them standalone: nix run github:polygon/audio.nix#vital
            # 2. Wait for upstream audio.nix to update for newer nixpkgs
            #
            # Affected packages:
            # - CHOW plugins: chow-tape-model, chow-centaur, chow-kick, chow-phaser, chow-multitool
            # - Synths: vital, atlas2, papu
          ])
        )
        # Video editing tools
        ++ optionals (cfg.video.enable && cfg.video.editing) [
          kdenlive # Non-linear video editor
          ffmpeg # Video encoding/decoding
          handbrake # Video transcoder
          # Additional video tools
          imagemagick # Image manipulation
          gimp # Image editor
        ]
        # Video streaming tools (consolidated - OBS can be enabled via video.streaming or streaming.obs)
        ++ optionals ((cfg.video.enable && cfg.video.streaming) || (cfg.streaming.enable && cfg.streaming.obs))
        [
          obs-studio # Open Broadcaster Software
        ]
        # Additional streaming tools (Linux-only)
        ++ optionals (isLinux && cfg.video.enable && cfg.video.streaming) [
          v4l2loopback # Virtual video loopback device (Linux-only)
        ]
    );

    # Enable musnix for real-time audio optimization (NixOS only)
    musnix = mkIf (isLinux && cfg.audio.enable && cfg.audio.realtime) {
      enable = true;
      # Real-time kernel and optimizations (only if realtime flag is set)
      kernel = {
        realtime = true;
        packages = pkgs.linuxPackages-rt_latest;
      };
      rtirq.enable = true;
    };

    # Enable rtkit for real-time scheduling (NixOS only)
    security.rtkit.enable = mkIf (isLinux && cfg.audio.enable) true;

    # Ensure user is in audio group for audio production
    users.users.${config.host.username}.extraGroups = optional (isLinux && cfg.audio.enable) "audio";

    # Assertions
    assertions = [
      {
        assertion = cfg.video.streaming -> cfg.streaming.enable || cfg.video.enable;
        message = "Video streaming requires either media.streaming.enable or media.video.enable";
      }
      {
        assertion = audioNixCfg.bitwig -> audioNixCfg.enable;
        message = "Bitwig Studio requires audioNix.enable to be true";
      }
      {
        assertion = audioNixCfg.plugins -> audioNixCfg.enable;
        message = "Audio plugins require audioNix.enable to be true";
      }
    ];
  };
}
