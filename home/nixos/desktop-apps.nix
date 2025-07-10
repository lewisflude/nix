{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    ddcutil

    # Media
    mpv
    imv

    # Office & Productivity
    libreoffice
    thunderbird
    evince

    # Graphics & Design
    gimp
    krita

    # Communication
    discord
    telegram-desktop

    # System Utilities
    file-roller
  ];

  # XDG MIME type associations for better file handling
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-terminal-emulator" = "ghostty.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "x-scheme-handler/onepassword" = "1password.desktop";
      "application/x-ms-dos-executable" = "wine.desktop";
      "application/x-wine-extension-ini" = "wine.desktop";
      "application/x-wine-extension-exe" = "wine.desktop";
      "application/x-wine-extension-msi" = "wine.desktop";
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
