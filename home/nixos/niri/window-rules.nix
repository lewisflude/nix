# Niri Window Rules Configuration
# Organized by: Visual Hierarchy → Security → Performance → Usability → Workspace Assignment
_: {
  window-rules = [
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
    {
      matches = [
        { is-floating = true; }
      ];
      geometry-corner-radius = {
        top-left = 12.0;
        top-right = 12.0;
        bottom-right = 12.0;
        bottom-left = 12.0;
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
        color = "#00000064";
      };
    }

    # Screencast indicator - visual feedback when window is being recorded
    {
      matches = [
        { is-window-cast-target = true; }
      ];
      focus-ring = {
        active = {
          color = "#f38ba8";
        };
        inactive = {
          color = "#7d0d2d";
        };
      };
      border = {
        inactive = {
          color = "#7d0d2d";
        };
      };
      shadow = {
        color = "#7d0d2d70";
      };
      tab-indicator = {
        active = {
          color = "#f38ba8";
        };
        inactive = {
          color = "#7d0d2d";
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
    # WORKSPACE ASSIGNMENT
    # ============================================================================

    # Browser windows - workspace 1
    {
      matches = [
        { app-id = "^chromium-browser$"; }
        { app-id = "^brave-browser$"; }
        { app-id = "^firefox$"; }
      ];
      open-on-workspace = "1";
    }

    # Development tools - workspace 3
    {
      matches = [
        { app-id = "^code$"; }
        { app-id = "^cursor$"; }
        { app-id = "^com\\.visualstudio\\.code.*"; }
        { app-id = "^dev\\.zed\\.Zed.*"; }
      ];
      open-on-workspace = "3";
    }

    # Communication apps - workspace 5
    {
      matches = [
        { app-id = "^discord$"; }
        { app-id = "^slack$"; }
        { app-id = "^signal$"; }
        { app-id = "^org\\.telegram\\.desktop$"; }
      ];
      open-on-workspace = "5";
    }

    # Email - workspace 5 (same as chat for communication grouping)
    {
      matches = [
        { app-id = "^thunderbird$"; }
      ];
      open-on-workspace = "5";
    }

    # Media apps - workspace 7
    {
      matches = [
        { app-id = "^obsidian$"; }
        { app-id = "^spotify$"; }
        { app-id = "^md\\.obsidian\\.Obsidian$"; }
      ];
      open-on-workspace = "7";
    }

    # ============================================================================
    # GAMING - WORKSPACE 9
    # ============================================================================

    # Gaming workspace 9 - isolated for performance and organization
    # This keeps Steam's noisy notifications and pop-ups separate from your work
    {
      matches = [
        { app-id = "^steam$"; }
        { title = "^Steam$"; }
      ];
      open-on-workspace = "9";
    }

    # Gamescope nested compositor - workspace 9 for gaming
    # Opens maximized for optimal gaming experience with VRR enabled
    {
      matches = [
        { app-id = "^gamescope$"; }
      ];
      default-column-width = {
        proportion = 1.0;
      };
      open-maximized = true;
      open-on-workspace = "9";
    }

    # Steam games - auto-focus by opening fullscreen on gaming workspace
    # This ensures games launched via Steam are immediately focused and isolated
    # VRR is enabled above for optimal gaming performance
    {
      matches = [
        { app-id = "^steam_app_.*"; }
      ];
      open-fullscreen = true;
      open-on-workspace = "9";
    }
  ];
}
