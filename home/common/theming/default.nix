{
  config,
  lib,
  palette,
  themeLib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;

  cfg = config.theming.signal;

  # Import theming utilities from shared location (single source of truth)
  # palette and themeLib are now available as module arguments
  modeLib = import ../../../modules/shared/features/theming/mode.nix {
    inherit lib config;
  };
  contextLib = import ../../../modules/shared/features/theming/context.nix { inherit lib; };

  # Resolve mode (handles "auto" mode by detecting system preference)
  resolvedMode = modeLib.getResolvedMode cfg;

  # Create theme context
  themeContext = contextLib.createContext {
    inherit themeLib palette;
    mode = resolvedMode;
  };
in
{
  # Import shared options (single source of truth) and application-specific theme modules
  imports = [
    ../../../modules/shared/features/theming/options.nix
    # Code editors
    ../../../modules/shared/features/theming/applications/editors/cursor.nix
    ../../../modules/shared/features/theming/applications/editors/helix.nix
    ../../../modules/shared/features/theming/applications/editors/zed.nix

    # Terminals
    ../../../modules/shared/features/theming/applications/terminals/ghostty.nix
    ../../../modules/shared/features/theming/applications/terminals/zellij.nix

    # Desktop environment (Linux)
    ../../../modules/shared/features/theming/applications/desktop/gtk.nix
    ../../../modules/shared/features/theming/applications/desktop/ironbar-home.nix
    ../../../modules/shared/features/theming/applications/desktop/swappy.nix

    # Command-line tools
    ../../../modules/shared/features/theming/applications/cli/bat.nix
    ../../../modules/shared/features/theming/applications/cli/fzf.nix
    ../../../modules/shared/features/theming/applications/cli/lazygit.nix
    ../../../modules/shared/features/theming/applications/cli/yazi.nix
  ];

  # Define Home Manager-specific application options
  options.theming.signal.applications = {
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

    gtk = {
      enable = mkEnableOption "Apply theme to GTK applications";
    };

    ironbar = {
      enable = mkEnableOption "Apply theme to Ironbar status bar";
    };

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

    satty = {
      enable = mkEnableOption "Apply theme to satty (screenshot annotation tool)";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Make theme context available to application modules via _module.args
      _module.args = {
        inherit themeContext;
        signalThemeLib = themeLib;
      };

      # Enable Zed theming by default when Signal theme is enabled
      # This ensures themes are generated for Zed on all platforms (not just NixOS)
      theming.signal.applications.zed.enable = lib.mkDefault true;
    }

    # Assertions and warnings
    {
      assertions = [
        # Mode resolution is now handled by mode.nix, so this assertion is no longer needed
        # Auto mode will be resolved to dark mode if system detection fails
        {
          assertion = cfg.brandGovernance.policy != "integrated" || cfg.brandGovernance.brandColors != { };
          message = "brandGovernance.policy = \"integrated\" requires brandGovernance.brandColors to be set";
        }
        {
          assertion = cfg.brandGovernance.policy == "integrated" || cfg.brandGovernance.brandColors == { };
          message = "brandGovernance.brandColors can only be used with policy = \"integrated\"";
        }
      ];

      warnings =
        lib.optional (cfg.overrides != { })
          "You are using color overrides. This may result in inconsistent theming. Consider using brandGovernance.brandColors for brand integration.";
    }
  ]);
}
