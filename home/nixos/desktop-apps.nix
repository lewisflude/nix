{ pkgs, ... }: {
  home.packages = with pkgs; [
    # File managers
    nautilus        # GNOME file manager
    nemo           # Cinnamon file manager (alternative)

    # Media players
    mpv            # Video player
    vlc            # Alternative video player
    rhythmbox      # Music player

    # Image viewers and editors
    eog            # Eye of GNOME image viewer
    loupe          # Modern GNOME image viewer
    gimp           # Image editor

    # Document viewers
    evince         # PDF viewer
    libreoffice    # Office suite

    # Web browsers (Firefox already configured in browser.nix)
    chromium       # Alternative browser

    # System utilities
    gnome-calculator
    gnome-calendar
    gnome-clocks
    gnome-weather

    # Archive managers
    file-roller    # GNOME archive manager

    # Text editors
    gedit          # Simple text editor

    # Development tools (optional, can be moved to separate dev config)
    vscodium       # Open source VS Code

    # Gaming utilities
    steam          # Steam gaming platform
    lutris         # Game launcher
    heroic         # Epic Games launcher
    bottles        # Wine environment manager

    # Communication
    discord        # Voice chat
    telegram-desktop  # Messaging

    # Productivity
    obsidian       # Note-taking

    # Graphics and design
    blender        # 3D modeling
    inkscape       # Vector graphics

    # System monitors
    htop           # Process monitor
    btop           # Modern system monitor

    # Clipboard manager
    clipse         # CLI clipboard manager (already in terminal.nix, but good to have)

    # Desktop utilities and tools
    fuzzel              # Application launcher
    mako                # Notification daemon
    grim                # Screenshot utility
    slurp               # Screen area selection
    swappy              # Screenshot editor
    lm_sensors          # Hardware sensors
    mangohud            # Gaming overlay
    goverlay            # MangoHud GUI
    piper               # Gaming mouse configuration
    cliphist            # Clipboard manager

    # Creative and media
    krita         # Digital painting

    # Productivity
    thunderbird    # Email client

    # Development (cross-platform)
    insomnia       # API testing
  ];

  # XDG MIME type associations for better file handling
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";

      "application/pdf" = "org.gnome.Evince.desktop";

      "image/jpeg" = "org.gnome.eog.desktop";
      "image/png" = "org.gnome.eog.desktop";
      "image/gif" = "org.gnome.eog.desktop";
      "image/webp" = "org.gnome.eog.desktop";

      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";

      "audio/mpeg" = "rhythmbox.desktop";
      "audio/flac" = "rhythmbox.desktop";
      "audio/x-vorbis+ogg" = "rhythmbox.desktop";

      "inode/directory" = "org.gnome.Nautilus.desktop";

      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
    };
  };
}