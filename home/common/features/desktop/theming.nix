# Desktop theming feature module
# Dendritic pattern: Uses osConfig instead of systemConfig
{
  lib,
  osConfig ? {},
  ...
}:
let
  cfg = osConfig.host.features.desktop or {};
in
{
  config = lib.mkIf (cfg.enable or false) {
    # Enable GTK theming
    # Signal will automatically apply colors via autoEnable
    gtk.enable = true;
  };
}
