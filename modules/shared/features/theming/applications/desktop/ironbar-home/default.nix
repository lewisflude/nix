# Ironbar Signal Theme Configuration Module
# Configures ironbar with Signal theme design system
# Implements formal design specification v1.0 (Relaxed profile for 1440p+)
#
# Architecture:
#   tokens.nix   - Design tokens (colors, spacing, typography, commands)
#   widgets.nix  - Widget builder helpers for reducing boilerplate
#   config.nix   - Widget configuration using tokens and builders
#   style.css    - GTK CSS implementing atomic design system
#   default.nix  - Home-manager module entry point (this file)
#
# Uses upstream ironbar home-manager module (imported globally in system-builders.nix)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  # Import design tokens
  tokens = import ./tokens.nix { };

  # Import configuration generator
  configModule = import ./config.nix { inherit pkgs lib; };

  # Style file path
  styleFile = ./style.css;

  cfg = config.theming.ironbar;
in
{
  # Note: ironbar home-manager module is imported globally in lib/system-builders.nix
  # We only configure the options here, not import the module

  options.theming.ironbar = {
    enable = mkEnableOption "Ironbar with Signal theme design system";

    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Additional configuration to merge with the Signal theme defaults.
        Uses lib.recursiveUpdate, so nested values can be overridden individually.

        Example: Override bar height and add custom widget
        ```nix
        theming.ironbar.extraConfig = {
          height = 42;
          end = [
            {
              type = "custom";
              name = "my-widget";
              # ... widget config ...
            }
          ];
        };
        ```
      '';
      example = lib.literalExpression ''
        {
          height = 42;
          popup_gap = 8;
          end = [
            {
              type = "custom";
              name = "weather";
              cmd = "curl wttr.in?format=1";
            }
          ];
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.ironbar = {
      enable = true;

      # Package Configuration
      # The upstream module applies: package.override {features = cfg.features;}
      # Since features defaults to [], this would rebuild with no features, breaking the build.
      # Solution: Use the default package which has all features pre-compiled.
      # Reference: https://github.com/JakeStanger/ironbar/blob/master/nix/module.nix#L18-20
      package = inputs.ironbar.packages.${pkgs.stdenv.hostPlatform.system}.default;

      # Systemd Integration
      # Automatically starts ironbar on login and enables hot-reload on config changes
      # Service integrates with wayland.systemd.target and tray.target
      systemd = true;

      # Styling
      # Accepts either a path (./style.css) or string content
      # The module automatically:
      #   1. Creates ~/.config/ironbar/style.css
      #   2. Triggers 'ironbar reload' on CSS changes (hot-reload)
      style = styleFile;

      # Configuration
      # Merges Signal theme defaults with user-provided extraConfig
      # The module automatically:
      #   1. Generates ~/.config/ironbar/config.json from this attrset
      #   2. Triggers 'ironbar reload' on config changes
      config = lib.recursiveUpdate configModule.config cfg.extraConfig;

      # Features
      # Intentionally left unset (defaults to [])
      # Do NOT set features = [ "tray" "workspaces" ... ];
      # This triggers the package override issue described above.
      # The pre-compiled package already includes all necessary features.
    };
  };
}
