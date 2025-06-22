{ pkgs, ... }: {

  home.packages = with pkgs; [
    hypridle
    nwg-dock-hyprland
    wl-clipboard
    brightnessctl
    nwg-drawer
  ];

  imports = [
    ./hyprland/default.nix
  ];

  # Hyprland configuration is handled in platform-specific modules
}

