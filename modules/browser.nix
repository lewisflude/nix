# Browser and MIME configuration (NixOS only)
# Dendritic pattern: Full implementation as flake.modules.homeManager.browser
_: {
  flake.modules.homeManager.browser =
    { lib, pkgs, ... }:
    let
      mimeAssoc = app: mimes: lib.genAttrs mimes (_: app);

      mimeDefaults = {
        "x-scheme-handler/http" = "google-chrome.desktop";
        "x-scheme-handler/https" = "google-chrome.desktop";
        "x-scheme-handler/mailto" = "thunderbird.desktop";
        "x-scheme-handler/magnet" = "transmission-gtk.desktop";
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "application/x-directory" = "org.gnome.Nautilus.desktop";
        "text/plain" = "helix.desktop";
        "text/html" = "google-chrome.desktop";
        "application/xhtml+xml" = "google-chrome.desktop";
        "text/markdown" = "helix.desktop";
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
        "x-terminal-emulator" = "ghostty.desktop";
        "x-scheme-handler/onepassword" = "1password.desktop";
        "x-scheme-handler/cursor" = "cursor-url-handler.desktop";
        "application/x-ms-dos-executable" = "wine.desktop";
        "application/x-wine-extension-ini" = "wine.desktop";
        "application/x-wine-extension-exe" = "wine.desktop";
        "application/x-wine-extension-msi" = "wine.desktop";
      };

      addedAssociations =
        lib.genAttrs
          [ "text/plain" "text/xml" "text/markdown" "text/css" "text/javascript" "text/x-python" ]
          (_: [
            "helix.desktop"
            "cursor.desktop"
          ])
        // lib.genAttrs [ "image/png" "image/jpeg" "image/gif" ] (_: [
          "swayimg.desktop"
          "gimp.desktop"
        ])
        // {
          "application/pdf" = [
            "google-chrome.desktop"
            "org.gnome.FileRoller.desktop"
          ];
          "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
        };

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
    in
    lib.mkIf pkgs.stdenv.isLinux {
      xdg.mimeApps = {
        enable = true;
        defaultApplications = mimeDefaults;
        associations.added = addedAssociations;
      };

      programs.google-chrome = {
        enable = true;
        commandLineArgs = chromeFlags;
      };
    };
}
