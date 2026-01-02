{ pkgs, ... }:
{
  home.packages = [
    pkgs.gimp
    pkgs.discord
    pkgs.telegram-desktop
    pkgs.file-roller
    # Note: libnotify is handled in core-tooling.nix
    # Note: swaylock-effects is handled in apps/swayidle.nix via programs.swaylock
    pkgs.font-awesome
    # FIXME: aseprite is currently broken in nixpkgs (skia-aseprite build failure)
    # Temporarily commented out until upstream fix is available
    # asepriteFixed
    pkgs.wl-screenrec

    # Thunar file manager with plugins
    pkgs.thunar
    pkgs.thunar-archive-plugin
    pkgs.thunar-volman
  ];

  services.cliphist = {
    enable = true;
  };
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
