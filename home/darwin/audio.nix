{ pkgs, ... }:
{
  # macOS-specific audio utilities for home-manager
  # macOS uses CoreAudio natively, so we only need CLI tools and utilities

  home.packages = [
    # Audio utilities
    pkgs.lame # MP3 encoding
    pkgs.flac # FLAC codec

    # Note: qjackctl (JACK control GUI) is Linux-only, not available on macOS
    # macOS users can use JACK Pilot or other native JACK tools if needed
  ];

  # macOS native audio control via System Preferences
  # No need for volume control utilities like pavucontrol
}
