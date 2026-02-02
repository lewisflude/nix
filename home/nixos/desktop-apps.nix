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
    pkgs.aseprite

    # Thunar file manager with plugins (primary)
    pkgs.thunar
    pkgs.thunar-archive-plugin
    pkgs.thunar-volman
    # Nautilus - needed by xdg-desktop-portal-gnome for file picker dialogs
    pkgs.nautilus
  ];

  # Clipboard manager disabled - DMS has built-in clipboard with history
  # To migrate from cliphist to DMS clipboard:
  #   dms clipboard cliphist-migrate
  # Configure clipboard via: dms settings clipboard
  services.cliphist.enable = false;

  # Note: MIME associations have been moved to browser.nix to avoid conflicts
  # All xdg.mimeApps configuration is now centralized in browser.nix

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
