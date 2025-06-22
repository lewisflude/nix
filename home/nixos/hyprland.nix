{ pkgs, hyprland, ... }:
{
  # Basic Hyprland enablement - detailed config is in home/common/desktop/hyprland/
  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprland.packages.${pkgs.system}.hyprland;
    systemd.enable = false; # Using UWSM instead of systemd
  };
}