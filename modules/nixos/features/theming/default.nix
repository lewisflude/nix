{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;

  cfg = config.theming.signal;

  # Import shared theming palette and library
  palette = import ../../../shared/features/theming/palette.nix { inherit lib; };
  themeLib = import ../../../shared/features/theming/lib.nix {
    inherit lib palette;
    nix-colorizer = config._module.args.nix-colorizer or null;
  };
  modeLib = import ../../../shared/features/theming/mode.nix {
    inherit lib config;
  };
  contextLib = import ../../../shared/features/theming/context.nix { inherit lib; };

  # Resolve mode (handles "auto" mode by detecting system preference)
  resolvedMode = modeLib.getResolvedMode cfg;

  # Create theme context
  themeContext = contextLib.createContext {
    inherit themeLib palette;
    mode = resolvedMode;
  };
in
{
  # Import shared options (single source of truth) and system-level application theming modules
  imports = [
    ../../../shared/features/theming/options.nix
    # Desktop applications (NixOS-specific)
    ../../../shared/features/theming/applications/desktop/fuzzel.nix
    ../../../shared/features/theming/applications/desktop/ironbar-nixos.nix
    ../../../shared/features/theming/applications/desktop/mako.nix
    ../../../shared/features/theming/applications/desktop/swaync.nix
  ];

  # Define NixOS-specific application options
  options.theming.signal.applications = {
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
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Make theme context available to application modules via _module.args
      _module.args = {
        inherit themeContext;
        signalThemeLib = themeLib;
      };
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
