{ pkgs, ... }:
{
  # macOS-specific audio utilities for home-manager
  # macOS uses CoreAudio natively, so we only need CLI tools and utilities

  home.packages = [
    # Audio utilities
    pkgs.lame # MP3 encoding
    pkgs.flac # FLAC codec

    # JACK audio (for professional audio routing if needed)
    pkgs.qjackctl # JACK control GUI
  ];

  # macOS native audio control via System Preferences
  # No need for volume control utilities like pavucontrol
}
