{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    mkMerge
    ;

  cfg = config.theming.scientific;

  # Import shared theming palette and library
  sharedThemingPath = ../../../shared/features/theming;
  palette = import "${sharedThemingPath}/palette.nix" { inherit lib; };
  themeLib = import "${sharedThemingPath}/lib.nix" { inherit lib palette; };

  # Generate the theme for the configured mode
  theme = themeLib.generateTheme cfg.mode;
in
{
  # Import system-level application theming modules
  imports = [
    ./applications/waybar.nix
    ./applications/fuzzel.nix
    ./applications/ironbar.nix
    ./applications/mako.nix
    ./applications/swaync.nix
    ./applications/swappy.nix
  ];

  options.theming.scientific = {
    enable = mkEnableOption "scientific OKLCH color palette theme";

    mode = mkOption {
      type = types.enum [
        "light"
        "dark"
        "auto"
      ];
      default = "dark";
      description = ''
        Color theme mode:
        - light: Use light mode colors
        - dark: Use dark mode colors
        - auto: Follow system preference (defaults to dark)
      '';
    };

    applications = {
      # Wayland/Linux desktop components
      waybar = {
        enable = mkEnableOption "Apply theme to Waybar (status bar)";
      };

      fuzzel = {
        enable = mkEnableOption "Apply theme to Fuzzel (application launcher)";
      };

      ironbar = {
        enable = mkEnableOption "Apply theme to Ironbar (status bar)";
      };

      mako = {
        enable = mkEnableOption "Apply theme to Mako (notification daemon)";
      };

      swaync = {
        enable = mkEnableOption "Apply theme to SwayNC (notification center)";
      };

      swappy = {
        enable = mkEnableOption "Apply theme to Swappy (screenshot annotation)";
      };
    };

    # Allow users to override specific colors (advanced usage)
    overrides = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            l = mkOption {
              type = types.float;
              description = "Lightness (0.0-1.0)";
            };
            c = mkOption {
              type = types.float;
              description = "Chroma (0.0-0.4+)";
            };
            h = mkOption {
              type = types.float;
              description = "Hue (0-360 degrees)";
            };
            hex = mkOption {
              type = types.str;
              description = "Hex color code";
            };
          };
        }
      );
      default = { };
      description = ''
        Override specific palette colors. Use with caution.
        Example: { "accent-primary" = { l = 0.7; c = 0.2; h = 130; hex = "#4db368"; }; }
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Make palette and theme available to application modules via _module.args
      _module.args.scientificPalette = theme;
      _module.args.scientificThemeLib = themeLib;
    }

    # Assertions and warnings
    {
      assertions = [
        {
          assertion = cfg.mode != "auto" || cfg.mode == "dark";
          message = "Auto mode is not fully implemented yet, defaulting to dark mode";
        }
      ];

      warnings = lib.optional (
        cfg.overrides != { }
      ) "You are using color overrides. This may result in inconsistent theming.";
    }
  ]);
}
