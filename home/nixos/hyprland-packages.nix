{ pkgs, ... }: {

  home.packages = with pkgs; [
    nwg-dock-hyprland
    wl-clipboard
    brightnessctl
    nwg-drawer
  ];


  # Hyprland configuration is handled in platform-specific modules
}

