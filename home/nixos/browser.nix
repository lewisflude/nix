{ lib, pkgs, ... }:
let
  # Helper to create MIME associations for a list of types
  mimeAssoc = app: mimes: lib.genAttrs mimes (_: app);

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
  }
  // mimeAssoc "swayimg.desktop" [
    "image/jpeg"
    "image/jpg"
    "image/png"
    "image/gif"
    "image/webp"
    "image/bmp"
    "image/svg+xml"
  ]
  // mimeAssoc "mpv.desktop" [
    "video/mp4"
    "video/webm"
    "video/x-matroska"
    "video/mpeg"
    "video/x-msvideo"
    "audio/mpeg"
    "audio/mp3"
    "audio/flac"
    "audio/ogg"
    "audio/x-vorbis+ogg"
    "audio/opus"
  ]
  // mimeAssoc "org.gnome.FileRoller.desktop" [
    "application/zip"
    "application/x-7z-compressed"
    "application/x-rar-compressed"
    "application/x-rar"
    "application/x-tar"
    "application/x-compressed-tar"
    "application/x-bzip-compressed-tar"
  ]
  // mimeAssoc "helix.desktop" [
    "application/x-shellscript"
    "application/x-executable"
  ]
  // {

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
  addedAssociations =
    lib.genAttrs
      [
        "text/plain"
        "text/xml"
        "text/markdown"
        "text/css"
        "text/javascript"
        "text/x-python"
      ]
      (_: [
        "helix.desktop"
        "cursor.desktop"
      ])
    // lib.genAttrs
      [
        "image/png"
        "image/jpeg"
        "image/gif"
      ]
      (_: [
        "swayimg.desktop"
        "gimp.desktop"
      ])
    // {
      "application/pdf" = [
        "google-chrome.desktop"
        "org.gnome.FileRoller.desktop"
      ];
      "inode/directory" = [
        "thunar.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };

  # Google Chrome command-line flags
  chromeFlags = [
    "--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,VaapiOnNvidiaGPUs"
    "--ignore-gpu-blocklist"
    "--enable-zero-copy"
    "--ozone-platform-hint=auto"
    "--enable-wayland-ime"
    "--enable-parallel-downloading"
    "--enable-gpu-rasterization"
    "--use-gl=egl"
    "--disk-cache-dir=/run/user/1000/chrome-cache"
    "--password-store=gnome-libsecret"
  ];

  chromeFlagsFormatted = lib.concatStringsSep "\n" chromeFlags;

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

  home.file.".config/chrome-flags.conf".text = chromeFlagsFormatted;
}
