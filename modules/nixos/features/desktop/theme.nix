{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{

  config = lib.mkIf cfg.enable (
    lib.mkMerge [

      # System-level Signal theme configuration (NixOS only)
      (lib.mkIf cfg.signalTheme.enable {
        theming.signal = {
          enable = true;
          inherit (cfg.signalTheme) mode;

          applications = {
            # Enable all Wayland/Linux desktop components
            fuzzel.enable = lib.mkDefault true;
            ironbar.enable = lib.mkDefault true;
            mako.enable = lib.mkDefault true;
            swaync.enable = lib.mkDefault true;
            swappy.enable = lib.mkDefault true;
          };
        };
      })
    ]
  );
}
