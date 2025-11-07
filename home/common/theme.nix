{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
in
{

  catppuccin = {
    flavor = "mocha";
    accent = "mauve";
    enable = false; # Disabled in favor of Scientific theme
    waybar.mode = "createLink";
    mako.enable = lib.mkIf platformLib.isLinux true;
    swaync.enable = lib.mkIf platformLib.isLinux true;
  };

  home = lib.optionalAttrs platformLib.isLinux {
    packages = with pkgs; [
      nwg-look

      iosevka-bin
      nerd-fonts.iosevka
      gtk4
    ];
    # Cursor theme configuration moved to theming system
    # Enable via: host.features.desktop.scientificTheme.enable = true
  };

  gtk = lib.mkIf platformLib.isLinux {
    enable = true;
    font = {
      name = "Iosevka";
      package = pkgs.iosevka-bin;
      size = 12;
    };
    # GTK theme and cursor configuration moved to theming system
    # Enable via: host.features.desktop.scientificTheme.enable = true
  };

  fonts.fontconfig.enable = lib.mkIf platformLib.isLinux true;
}
