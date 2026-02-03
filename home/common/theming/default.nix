{
  lib,
  pkgs,
  ...
}:
# signal-nix theming is Linux-only (GTK theme)
# Use mkIf to conditionally enable on Linux only
{
  theming.signal = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    autoEnable = true;
    mode = "dark";

    # Explicitly enable ironbar colors (required when using colors.ironbar in config)
    ironbar.enable = true;

    # Niri compositor theming: ENABLED
    # Signal-nix generates semantic colors in dms/signal-colors.kdl
    # DMS provides functionality (keybinds, layout, widgets) - signal-nix owns colors
    desktop.compositors.niri = {
      enable = true;
      exportKdl = true; # Generates signal-colors.kdl for DMS integration
    };
  };
}
