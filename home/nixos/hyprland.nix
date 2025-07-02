{ ... }:
{
  # Basic Hyprland enablement - detailed config is in home/common/desktop/hyprland/
  wayland.windowManager.hyprland = {
    enable = false;
    package = null;
    portalPackage = null;
    systemd.variables = [ "--all" ];
  };
}
