{pkgs, ...}: {
  home.packages = with pkgs; [
    ddcutil
    displaycal

    # Media
    mpv
    swayimg # Wayland-native image viewer with better scaling

    # Office & Productivity
    libreoffice
    evince
    kicad

    # Graphics & Design
    gimp
    krita
    aseprite
    pixelorama # Free, open-source pixel art editor with excellent Wayland support

    # Communication
    discord
    telegram-desktop

    # System Utilities
    file-roller
    libnotify
    swaylock-effects
    dragon-drop # Drag and drop from terminal to GUI apps

    # File Manager (Nautilus) - Wayland-native file manager
    nautilus
    sushi # File previewer for Nautilus
    ffmpegthumbnailer
    gvfs # Virtual filesystem support

    # Game Development
    love # Love2D game engine

    # Electronics/Circuit Design
    ngspice # Next Generation Spice (Electronic Circuit Simulator)
    qucs-s # Circuit simulator with GUI (Qucs-S)

    # Audio Production & Music
    ardour # Professional DAW
    qjackctl # JACK audio connection kit control
    guitarix # Guitar amplifier simulator and effects
    rakarrack # Real-time guitar effects processor
    calf # Professional audio plugins
    helm # Polyphonic synthesizer
    surge-XT # Hybrid synthesizer
    vital # Modern wavetable synthesizer
    dexed # DX7 FM synthesizer
    vcv-rack # Modular synthesizer simulator

    # Audio Programming & DSP
    puredata # Visual programming for audio (Pure Data)

    # Audio Analysis & Measurement
    jaaa # Audio analyzer (JACK-based)

    # Fonts required for applications
    font-awesome # Required for swappy icons
  ];
  services.cliphist = {
    enable = true;
  };
  # XDG MIME type associations for better file handling
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-terminal-emulator" = "ghostty.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "application/x-directory" = "org.gnome.Nautilus.desktop";
      "x-scheme-handler/onepassword" = "1password.desktop";
      "application/x-ms-dos-executable" = "wine.desktop";
      "application/x-wine-extension-ini" = "wine.desktop";
      "application/x-wine-extension-exe" = "wine.desktop";
      "application/x-wine-extension-msi" = "wine.desktop";

      # Image file associations for swayimg
      "image/jpeg" = "swayimg.desktop";
      "image/jpg" = "swayimg.desktop";
      "image/png" = "swayimg.desktop";
      "image/gif" = "swayimg.desktop";
      "image/webp" = "swayimg.desktop";
      "image/bmp" = "swayimg.desktop";
      "image/svg+xml" = "swayimg.desktop";
    };
  };

  xdg.desktopEntries.ghostty = {
    name = "Ghostty";
    exec = "${pkgs.ghostty}/bin/ghostty";
    terminal = false;
    type = "Application";
    categories = [
      "TerminalEmulator"
      "System"
    ];
  };
}
