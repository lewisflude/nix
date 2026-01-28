{ pkgs, ... }:
{
  # Cross-platform audio utilities for home-manager

  home.packages = [
    # Format converters and processing
    pkgs.ffmpeg # Audio/video conversion (saves ~1GB vs ffmpeg-full by excluding whisper-cpp)
    pkgs.flac
    pkgs.lame
    pkgs.opusTools


  ];

  # Note: MPV is configured separately in home/nixos/apps/mpv.nix
}
