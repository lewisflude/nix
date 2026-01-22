{
  lib,
  systemConfig,
  ...
}:
let
  cfg = systemConfig.host.features.desktop;
in
{

  config = lib.mkIf cfg.enable {
    # Enable GTK theming
    # Signal will automatically apply colors via autoEnable
    gtk.enable = true;
  };
}
