{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    nwg-dock-hyprland
    nwg-drawer
    nwg-displays
    nwg-look
  ];
  services = {
    hyprpaper = {
      enable = true;
      settings = {
        ipc = true;
        preload = [
          "${config.home.homeDirectory}/wallpapers/nix-wallpaper-nineish-catppuccin-mocha.png"
        ];
        wallpaper = ",${config.home.homeDirectory}/wallpapers/nix-wallpaper-nineish-catppuccin-mocha.png";
        "wallpaper DP-1,fit" =
          "${config.home.homeDirectory}/wallpapers/nix-wallpaper-nineish-catppuccin-mocha.png";
      };
    };
  };
}
