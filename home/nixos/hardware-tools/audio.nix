{ pkgs, ... }:
{
  # NixOS-specific audio utilities for PipeWire/PulseAudio

  home.packages = [
    # PipeWire control and utilities
    pkgs.pwvucontrol # Modern PipeWire volume control (GTK4)
    pkgs.helvum # PipeWire patchbay for audio routing

    # PulseAudio compatibility tools
    pkgs.pavucontrol # PulseAudio volume control (works with PipeWire)
    pkgs.paprefs # PulseAudio preferences

    # Media control
    pkgs.playerctl # MPRIS media player controller

    # Audio utilities
    pkgs.easyeffects # Audio effects for PipeWire
    pkgs.qpwgraph # Qt-based PipeWire graph manager
  ];

  # Playerctl configuration for media key bindings
  services.playerctld.enable = true;
}
