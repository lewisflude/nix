# Widget builder helpers for Ironbar configuration
# Reduces boilerplate and ensures consistency across widget definitions
# Based on Ironbar module options: https://github.com/JakeStanger/ironbar/blob/master/nix/module.nix
{
  lib,
  pkgs,
  tokens,
}:
let
  inherit (lib) mkMerge filterAttrs;

  # Helper: Build widget with optional attributes
  # Filters out null values and merges base config with optional attrs
  mkWidget =
    baseConfig: optionalConfig:
    mkMerge [
      baseConfig
      (filterAttrs (_: v: v != null) optionalConfig)
    ];
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
    mkWidget
      {
        inherit
          type
          name
          format
          class
          ;
      }
      (
        {
          inherit icon tooltip;
        }
        // interactions
        // extraConfig
      );

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
    mkWidget {
      type = "script";
      inherit
        name
        class
        cmd
        format
        mode
        interval
        ;
    } { inherit tooltip; };

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
    mkWidget
      {
        type = "launcher";
        inherit name class cmd;
      }
      {
        inherit icon tooltip;
        icon_size = iconSize;
      };
}
