{ pkgs, ... }:
{
  # Audio control utilities for PipeWire
  home.packages = [
    pkgs.pwvucontrol
    pkgs.pulsemixer
    pkgs.pamixer
    pkgs.playerctl
  ];
}
