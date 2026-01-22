{ lib, pkgs, ... }:
let
  # Core default applications for each MIME type
  mimeDefaults = {
    # Core Handlers
    "x-scheme-handler/http" = "google-chrome.desktop";
    "x-scheme-handler/https" = "google-chrome.desktop";
    "x-scheme-handler/mailto" = "thunderbird.desktop";
    # Note: Uncomment the preferred torrent client:
    # "x-scheme-handler/magnet" = "org.qbittorrent.qBittorrent.desktop";
    "x-scheme-handler/magnet" = "transmission-gtk.desktop";
    "inode/directory" = "thunar.desktop";
    "application/x-directory" = "thunar.desktop";

    # Text & Web
    "text/plain" = "helix.desktop";
    "text/html" = "google-chrome.desktop";
    "application/xhtml+xml" = "google-chrome.desktop";
    "text/markdown" = "helix.desktop";

    # Documents & Media - PDFs
    "application/pdf" = "google-chrome.desktop";

    # Documents & Media - Images
    "image/jpeg" = "swayimg.desktop";
    "image/jpg" = "swayimg.desktop";
    "image/png" = "swayimg.desktop";
    "image/gif" = "swayimg.desktop";
    "image/webp" = "swayimg.desktop";
    "image/bmp" = "swayimg.desktop";
    "image/svg+xml" = "swayimg.desktop";

    # Documents & Media - Video
    "video/mp4" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "video/mpeg" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";

    # Documents & Media - Audio
    "audio/mpeg" = "mpv.desktop";
    "audio/mp3" = "mpv.desktop";
    "audio/flac" = "mpv.desktop";
    "audio/ogg" = "mpv.desktop";
    "audio/x-vorbis+ogg" = "mpv.desktop";
    "audio/opus" = "mpv.desktop";

    # Archives & Execution
    "application/zip" = "org.gnome.FileRoller.desktop";
    "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
    "application/x-rar-compressed" = "org.gnome.FileRoller.desktop";
    "application/x-rar" = "org.gnome.FileRoller.desktop";
    "application/x-tar" = "org.gnome.FileRoller.desktop";
    "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
    "application/x-bzip-compressed-tar" = "org.gnome.FileRoller.desktop";
    "application/x-shellscript" = "helix.desktop";
    "application/x-executable" = "helix.desktop";

    # Additional platform-specific handlers
    "x-terminal-emulator" = "ghostty.desktop";
    "x-scheme-handler/onepassword" = "1password.desktop";
    "x-scheme-handler/cursor" = "cursor-url-handler.desktop";

    # Wine executables
    "application/x-ms-dos-executable" = "wine.desktop";
    "application/x-wine-extension-ini" = "wine.desktop";
    "application/x-wine-extension-exe" = "wine.desktop";
    "application/x-wine-extension-msi" = "wine.desktop";
  };

  # Additional associations (alternatives that can also handle these types)
  addedAssociations = {
    # Text files - offer both Helix and Cursor as options
    "text/plain" = [
      "helix.desktop"
      "cursor.desktop"
    ];
    "text/xml" = [
      "helix.desktop"
      "cursor.desktop"
    ];
    "text/markdown" = [
      "helix.desktop"
      "cursor.desktop"
    ];
    "text/css" = [
      "helix.desktop"
      "cursor.desktop"
    ];
    "text/javascript" = [
      "helix.desktop"
      "cursor.desktop"
    ];
    "text/x-python" = [
      "helix.desktop"
      "cursor.desktop"
    ];

    # PDFs - also offer file-roller for extraction
    "application/pdf" = [
      "google-chrome.desktop"
      "org.gnome.FileRoller.desktop"
    ];

    # Images - offer GIMP as alternative editor
    "image/png" = [
      "swayimg.desktop"
      "gimp.desktop"
    ];
    "image/jpeg" = [
      "swayimg.desktop"
      "gimp.desktop"
    ];
    "image/gif" = [
      "swayimg.desktop"
      "gimp.desktop"
    ];

    # File manager alternatives
    "inode/directory" = [
      "thunar.desktop"
      "org.gnome.Nautilus.desktop"
    ];
  };

  # Google Chrome command-line flags for performance and features
  # Reference: https://wiki.archlinux.org/title/Chromium
  chromeFlags = [
    # Hardware acceleration (VA-API for video decode)
    # Note: VaapiOnNvidiaGPUs is required for NVIDIA GPUs (Jupiter uses RTX 4090)
    "--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,VaapiOnNvidiaGPUs"

    # GPU acceleration (force past blocklist if needed)
    "--ignore-gpu-blocklist"
    "--enable-zero-copy"

    # Wayland support (auto-detect X11 vs Wayland)
    "--ozone-platform-hint=auto"
    "--enable-wayland-ime"

    # Performance optimizations
    "--enable-parallel-downloading"
    "--enable-gpu-rasterization"

    # High refresh rate support (for gaming displays)
    "--use-gl=egl"

    # Cache in tmpfs (reduces disk writes, improves performance)
    "--disk-cache-dir=/run/user/1000/chrome-cache"

    # Password store (use GNOME Keyring consistently)
    "--password-store=gnome-libsecret"
  ];

  # Format flags for chrome-flags.conf (one per line with comments)
  chromeFlagsFormatted = lib.concatMapStringsSep "\n" (flag: flag) chromeFlags;

in
{
  # Home-Manager MIME associations
  # Note: Use xdg.mimeApps (home-manager), not xdg.mime (NixOS system option)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = mimeDefaults;
    associations.added = addedAssociations;
  };

  # Install Google Chrome
  home.packages = [ pkgs.google-chrome ];

  # Google Chrome persistent flags configuration
  # Note: For Chromium use chromium-flags.conf instead
  # These flags are read by the Chrome launcher script
  home.file.".config/chrome-flags.conf".text = ''
    # Chrome Performance & Feature Flags
    # Generated by NixOS Home Manager
    # See: https://wiki.archlinux.org/title/Chromium

    # Hardware Video Acceleration (VA-API)
    # Enables GPU-accelerated video decoding for better performance
    ${chromeFlagsFormatted}
  '';
}
