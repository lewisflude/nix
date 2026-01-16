# Widget builder helpers for Ironbar configuration
# Reduces boilerplate and ensures consistency across widget definitions
# Based on Ironbar module options: https://github.com/JakeStanger/ironbar/blob/master/nix/module.nix
{
  lib,
  pkgs,
  tokens,
}:
let
  inherit (lib) mkMerge optionalAttrs;
in
{
  # Control widget builder (brightness, volume, etc.)
  # Creates interactive widgets with consistent structure
  mkControlWidget =
    {
      type,
      name,
      format,
      icon ? null,
      class ? "${name} control-button",
      interactions ? { },
      extraConfig ? { },
      tooltip ? null,
    }:
    mkMerge [
      {
        inherit
          type
          name
          format
          class
          ;
      }
      (optionalAttrs (icon != null) { inherit icon; })
      (optionalAttrs (tooltip != null) { inherit tooltip; })
      interactions
      extraConfig
    ];

  # Script widget builder (layout indicator, custom scripts)
  # For polling or watching external commands
  mkScriptWidget =
    {
      name,
      class,
      cmd,
      format ? "{output}",
      mode ? "poll",
      interval ? 1000,
      tooltip ? null,
    }:
    mkMerge [
      {
        type = "script";
        inherit
          name
          class
          cmd
          format
          mode
          interval
          ;
      }
      (optionalAttrs (tooltip != null) { inherit tooltip; })
    ];

  # Launcher widget builder (power button, app launchers)
  # Executes commands when clicked
  mkLauncherWidget =
    {
      name,
      class,
      cmd,
      icon ? null,
      iconSize ? null,
      tooltip ? null,
    }:
    mkMerge [
      {
        type = "launcher";
        inherit name class cmd;
      }
      (optionalAttrs (icon != null) { inherit icon; })
      (optionalAttrs (iconSize != null) { icon_size = iconSize; })
      (optionalAttrs (tooltip != null) { inherit tooltip; })
    ];
}
