{ pkgs, ... }:
let
  cmakePolicyFlag = "-DCMAKE_POLICY_VERSION_MINIMUM=3.5";
  asepriteFixed = pkgs.aseprite.overrideAttrs (prev: {
    cmakeFlags = (prev.cmakeFlags or [ ]) ++ [ cmakePolicyFlag ];
  });
in
{
  home.packages = with pkgs; [
    mpv
    gimp
    discord
    telegram-desktop
    file-roller
    # Note: libnotify is handled in core-tooling.nix
    swaylock-effects
    xfce.thunar
    font-awesome
    asepriteFixed
    wl-screenrec
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
