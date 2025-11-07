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

  # Import theming palette and library (local copies for home-manager)
  palette = import ./palette.nix { inherit lib; };
  themeLib = import ./lib.nix { inherit lib palette; };

  # Generate the theme for the configured mode
  theme = themeLib.generateTheme cfg.mode;
in
{
  # Import application-specific theme modules at top level
  imports = [
    # Code editors and terminals
    ./applications/cursor.nix
    ./applications/helix.nix
    ./applications/zed.nix
    ./applications/ghostty.nix

    # Desktop environment (Linux)
    ./applications/gtk.nix

    # Command-line tools
    ./applications/bat.nix
    ./applications/fzf.nix
    ./applications/lazygit.nix
    ./applications/yazi.nix
    ./applications/zellij.nix
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
      # Code editors and terminals
      cursor = {
        enable = mkEnableOption "Apply theme to Cursor/VS Code";
      };

      helix = {
        enable = mkEnableOption "Apply theme to Helix editor";
      };

      zed = {
        enable = mkEnableOption "Apply theme to Zed editor";
      };

      ghostty = {
        enable = mkEnableOption "Apply theme to Ghostty terminal";
      };

      # Desktop environment (Linux - user-level)
      gtk = {
        enable = mkEnableOption "Apply theme to GTK applications";
      };

      # Command-line tools (user-level)
      bat = {
        enable = mkEnableOption "Apply theme to bat (syntax highlighting)";
      };

      fzf = {
        enable = mkEnableOption "Apply theme to fzf (fuzzy finder)";
      };

      lazygit = {
        enable = mkEnableOption "Apply theme to lazygit (Git TUI)";
      };

      yazi = {
        enable = mkEnableOption "Apply theme to yazi (file manager)";
      };

      zellij = {
        enable = mkEnableOption "Apply theme to zellij (terminal multiplexer)";
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
