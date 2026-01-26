{ pkgs, ... }:
{
  # Cross-platform audio utilities for home-manager

  home.packages = [
    # Format converters and processing
    pkgs.ffmpeg-full # Comprehensive audio/video conversion (includes most sox functionality)
    pkgs.flac
    pkgs.lame
    pkgs.opusTools


  ];

  # Note: MPV is configured separately in home/nixos/apps/mpv.nix
}
