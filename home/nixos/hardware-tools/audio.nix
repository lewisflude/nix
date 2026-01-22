{ pkgs, ... }:
{
  # NixOS-specific audio utilities for PipeWire/PulseAudio

  home.packages = [
    # PipeWire control and utilities
    pkgs.pwvucontrol # Modern PipeWire volume control (GTK4)
    pkgs.helvum # PipeWire patchbay for audio routing
    pkgs.qpwgraph # Qt-based PipeWire graph manager

    # PulseAudio compatibility tools
    pkgs.pavucontrol # PulseAudio volume control (works with PipeWire)
    pkgs.paprefs # PulseAudio preferences

    # Media control
    pkgs.playerctl # MPRIS media player controller

    # Audio effects and processing
    pkgs.easyeffects # Audio effects for PipeWire

    # Pro audio tools and diagnostics
    pkgs.jack2 # JACK Audio Connection Kit (for jack_delay latency testing)
    # jack_delay - measures round-trip latency through audio interface
    # Usage: jack_delay -O system:playback_1 -I system:capture_1
  ];

  # Playerctl configuration for media key bindings
  services.playerctld.enable = true;

  # Note: Auto-linking is now handled by PipeWire's loopback module
  # with node.passive=false and stream.capture.sink configured.
  # The systemd service is no longer needed.

  # Note: PipeWire Pro Audio Profile
  # To enable PipeWire's Pro Audio profile for lower latency:
  # 1. Open pavucontrol
  # 2. Go to Configuration tab
  # 3. Select "Pro Audio" profile for your audio device
  # This profile exposes individual channels and provides lower latency
}
