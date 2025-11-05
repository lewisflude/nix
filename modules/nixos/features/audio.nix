# Audio feature module for NixOS
# Controlled by host.features.audio.*
# Note: This module focuses on music production features.
# Basic PipeWire audio is configured in modules/nixos/desktop/audio/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.audio;
  audioNixCfg = cfg.audioNix;
in
{
  config = mkIf cfg.enable {
    # Enable musnix for real-time audio optimization
    musnix = {
      enable = true;
      # Real-time kernel and optimizations (only if realtime flag is set)
      kernel = mkIf cfg.realtime {
        realtime = true;
        packages = pkgs.linuxPackages-rt_latest;
      };
      rtirq.enable = cfg.realtime;
    };

    # Enable rtkit for real-time scheduling
    security.rtkit.enable = true;

    # Audio production packages
    environment.systemPackages =
      with pkgs;
      # Standard audio production packages
      (optionals cfg.production [
        # ardour # TEMPORARILY DISABLED: depends on webkitgtk which was removed
        audacity
        helm
        lsp-plugins
        # zyn-fusion # TEMPORARILY DISABLED: may depend on webkitgtk which was removed
      ])
      # Audio.nix packages (from polygon/audio.nix flake)
      ++ (optionals audioNixCfg.enable (
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
      ));

    # Ensure user is in audio group
    users.users.${config.host.username}.extraGroups = optional cfg.enable "audio";
  };
}
