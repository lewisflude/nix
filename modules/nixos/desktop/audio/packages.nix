{pkgs, ...}: {
  # Audio-related packages
  environment.systemPackages = with pkgs; [
    pavucontrol # PulseAudio volume control
    pulsemixer # Terminal-based mixer
    pamixer # Command-line mixer
    playerctl # Media player control
  ];

  # Enable musnix for pro audio optimization
  musnix.enable = true;

  # Enable real-time audio scheduling
  security.rtkit.enable = true;
}
