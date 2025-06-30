{ pkgs, hyprland, ... }:
{
  # Basic Hyprland enablement - detailed config is in home/common/desktop/hyprland/
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
    systemd.variables = [ "--all" ];
  };

}
