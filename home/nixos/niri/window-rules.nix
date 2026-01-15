# Niri Window Rules Configuration
# Organized by: Visual Hierarchy → Security → Performance → Usability → Workspace Assignment
#
# IMPORTANT: Corner radius is synchronized with Ironbar tokens
# to create visual harmony between windows and the bar.
# See: modules/shared/features/theming/applications/desktop/ironbar-home/tokens.nix
{
  themeLib,
  ironbarTokens,
  ...
}:
let
  # Generate theme to access raw colors
  theme = themeLib.generateTheme "dark" { };
  inherit (theme) colors;

  # Synchronized values from Ironbar design tokens
  # This ensures Niri windows use the same corner radius as Ironbar islands
  inherit (ironbarTokens) niriSync;

  # Convert integer to float for Niri config
  cornerRadius = niriSync.windowRadius * 1.0;

  # Screencast indicator colors - uses danger/urgent colors for visibility
  screencastColors = {
    active = colors."accent-danger".hex;
    inactive = "#7d0d2d"; # Darker variant of danger for inactive state
    shadow = "#7d0d2d70"; # With transparency
  };

  # Floating window shadow - matches layout shadow color
  floatingShadowColor = "${colors."surface-base".hex}aa";
in
{
  window-rules = [
    # ============================================================================
    # GLOBAL DEFAULTS
    # ============================================================================

    # Global rounded corners for all windows
    # Radius synchronized with Ironbar island radius (8pt grid: compact = 12px, relaxed = 16px)
    # Applied first so specific rules can override if needed
    {
      geometry-corner-radius = {
        top-left = cornerRadius;
        top-right = cornerRadius;
        bottom-right = cornerRadius;
        bottom-left = cornerRadius;
      };
      clip-to-geometry = true;
    }

    # ============================================================================
    # VISUAL HIERARCHY & FOCUS
    # ============================================================================

    # Inactive window dimming - helps identify focused window
    {
      matches = [
        { is-active = false; }
      ];
      opacity = 0.95;
    }

    # Floating windows - enhanced aesthetics with rounded corners and shadows
    # Corner radius synchronized with Ironbar islands
    {
      matches = [
        { is-floating = true; }
      ];
      geometry-corner-radius = {
        top-left = cornerRadius;
        top-right = cornerRadius;
        bottom-right = cornerRadius;
        bottom-left = cornerRadius;
      };
      clip-to-geometry = true;
      shadow = {
        enable = true;
        softness = 40;
        spread = 5;
        offset = {
          x = 0;
          y = 5;
        };
        color = floatingShadowColor;
      };
    }

    # Screencast indicator - visual feedback when window is being recorded
    {
      matches = [
        { is-window-cast-target = true; }
      ];
      focus-ring = {
        active = {
          color = screencastColors.active;
        };
        inactive = {
          color = screencastColors.inactive;
        };
      };
      border = {
        inactive = {
          color = screencastColors.inactive;
        };
      };
      shadow = {
        color = screencastColors.shadow;
      };
      tab-indicator = {
        active = {
          color = screencastColors.active;
        };
        inactive = {
          color = screencastColors.inactive;
        };
      };
    }

    # Disable shadows for notifications (SwayNC)
    # Fixes background "spilling out" beyond borders issue
    {
      matches = [
        { app-id = "^org\\.erikreider\\.swaync.*"; }
      ];
      shadow.enable = false;
    }

    # ============================================================================
    # SECURITY & PRIVACY
    # ============================================================================

    # Password managers - block from screencasts for security
    {
      matches = [
        { app-id = "^org\\.keepassxc\\.KeePassXC$"; }
        { app-id = "^Bitwarden$"; }
        { app-id = "^1Password$"; }
        { app-id = "^com\\.bitwarden\\.desktop$"; }
      ];
      block-out-from = "screencast";
    }

    # ============================================================================
    # PERFORMANCE OPTIMIZATION
    # ============================================================================

    # Variable refresh rate for games and video players
    {
      matches = [
        { app-id = "^steam_app_.*"; }
        { app-id = "^gamescope$"; }
        { app-id = "^mpv$"; }
        { app-id = "^vlc$"; }
      ];
      variable-refresh-rate = true;
    }

    # ============================================================================
    # USABILITY & SMART BEHAVIORS
    # ============================================================================

    # File pickers - floating for easier file selection
    {
      matches = [
        { title = "^Open File$"; }
        { title = "^Save File$"; }
        { title = "^Save As$"; }
        { title = "^Select.*"; }
        { app-id = "^org\\.gnome\\.NautilusPreviewer$"; }
        { app-id = "^xdg-desktop-portal-gtk$"; }
        { app-id = "^xdg-desktop-portal-kde$"; }
      ];
      open-floating = true;
      default-column-width = {
        fixed = 900;
      };
      default-window-height = {
        fixed = 600;
      };
    }

    # System dialogs - floating for better UX
    {
      matches = [
        { app-id = "^org\\.freedesktop\\.impl\\.portal\\.desktop\\..*"; }
        { app-id = "^polkit-gnome-authentication-agent-.*"; }
        { app-id = "^gcr-prompter$"; }
        { app-id = "^zenity$"; }
        { app-id = "^yad$"; }
      ];
      open-floating = true;
      max-width = 600;
    }

    # Picture-in-Picture windows - positioned at bottom-right corner
    {
      matches = [
        {
          app-id = "firefox$";
          title = "^Picture-in-Picture$";
        }
        {
          app-id = "^chromium";
          title = "^Picture-in-Picture$";
        }
        {
          app-id = "^brave-browser$";
          title = "^Picture-in-Picture$";
        }
      ];
      open-floating = true;
      default-column-width = {
        fixed = 480;
      };
      default-window-height = {
        fixed = 270;
      };
      default-floating-position = {
        x = 32.0;
        y = 32.0;
        relative-to = "bottom-right";
      };
    }

    # Don't focus splash screens and startup dialogs
    {
      matches = [
        {
          app-id = "^gimp";
          title = "^GIMP Startup$";
        }
      ];
      open-focused = false;
    }

    # OBS minimum width fix - prevents layout issues with server-side decorations
    {
      matches = [
        { app-id = "^com\\.obsproject\\.Studio$"; }
      ];
      min-width = 876;
    }

    # Firefox/Thunderbird 1px border fix
    # These apps draw their own 1px dark border that obscures niri's border
    {
      matches = [
        { app-id = "^firefox$"; }
        { app-id = "^thunderbird$"; }
      ];
      clip-to-geometry = true;
    }

    # Document viewers - tabbed display by default for better organization
    {
      matches = [
        { app-id = "^evince$"; }
        { app-id = "^org\\.pwmt\\.zathura$"; }
        { app-id = "^org\\.gnome\\.Evince$"; }
      ];
      default-column-display = "tabbed";
    }

    # DisplayCal - floating for color calibration workflows
    {
      matches = [
        { app-id = "^displaycal$"; }
      ];
      default-column-width = { };
      open-floating = true;
    }

    # ============================================================================
    # GAMING
    # ============================================================================

    # Gamescope nested compositor - opens maximized for optimal gaming experience
    # VRR is enabled above in the performance section
    {
      matches = [
        { app-id = "^gamescope$"; }
      ];
      default-column-width = {
        proportion = 1.0;
      };
      open-maximized = true;
    }

    # Steam games - open fullscreen for immersive gaming
    # VRR is enabled above for optimal gaming performance
    {
      matches = [
        { app-id = "^steam_app_.*"; }
      ];
      open-fullscreen = true;
    }
  ];
}
