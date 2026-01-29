# Niri Window Rules Configuration - Streamlined (10 essential rules)
# Organized by: Global → Security → Performance → Usability
_: {
  window-rules = [
    # ============================================================================
    # GLOBAL DEFAULTS
    # ============================================================================

    # Global rounded corners for all windows (8px for tight 8pt grid)
    {
      geometry-corner-radius = {
        top-left = 8.0;
        top-right = 8.0;
        bottom-right = 8.0;
        bottom-left = 8.0;
      };
      clip-to-geometry = true;
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
          app-id = "^google-chrome";
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

    # Firefox/Thunderbird 1px border fix
    # These apps draw their own 1px dark border that obscures niri's border
    {
      matches = [
        { app-id = "^firefox$"; }
        { app-id = "^thunderbird$"; }
      ];
      clip-to-geometry = true;
    }

    # OBS minimum width fix - prevents layout issues with server-side decorations
    {
      matches = [
        { app-id = "^com\\.obsproject\\.Studio$"; }
      ];
      min-width = 876;
    }

    # Steam games - open fullscreen for immersive gaming
    # VRR is enabled above for optimal gaming performance
    {
      matches = [
        { app-id = "^steam_app_.*"; }
      ];
      open-fullscreen = true;
    }

    # Floating windows - focus on creation for better UX
    {
      matches = [
        { is-floating = true; }
      ];
      open-focused = true;
    }
  ];
}
