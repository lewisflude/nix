{
  config,
  lib,
  pkgs,
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
  # Note: Most theming is now handled by Signal flake
  # This file provides local application theming (cursor, zed, satty, ironbar) and theme context
  imports = [
    ../../../modules/shared/features/theming/applications/editors/cursor.nix
    ../../../modules/shared/features/theming/applications/editors/zed.nix
    ../../../modules/shared/features/theming/applications/desktop/satty.nix
    ../../../modules/shared/features/theming/applications/desktop/ironbar-home.nix
  ];

  # Define local application options (apps not in signal flake or have local customizations)
  options.theming.signal.local = {
    applications = {
      cursor = {
        enable = mkEnableOption "Apply theme to Cursor/VS Code";
      };

      zed = {
        enable = mkEnableOption "Apply theme to Zed editor";
      };

      satty = {
        enable = mkEnableOption "Apply theme to satty (screenshot annotation tool)";
      };
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

    (mkIf pkgs.stdenv.isLinux {
      # Service to detect system theme preference
      # This runs on login and when requested to update the cached theme mode
      systemd.user.services.detect-theme-mode = {
        Unit = {
          Description = "Detect system theme preference";
          Documentation = "man:gsettings(1)";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart =
            let
              script = pkgs.writeShellScript "detect-theme" ''
                mkdir -p "${config.xdg.cacheHome}"

                # Try multiple sources in order
                # 1. GNOME Interface settings (standard for most GTK desktops)
                theme=$(${pkgs.glib}/bin/gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "")

                # Determine mode based on setting
                if [[ "$theme" =~ "dark" ]]; then
                  echo "dark" > "${config.xdg.cacheHome}/theme-mode"
                else
                  echo "light" > "${config.xdg.cacheHome}/theme-mode"
                fi
              '';
            in
            "${script}";
        };
      };
    })

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

      warnings = [ ];
    }
  ]);
}
