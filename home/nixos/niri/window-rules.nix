# Niri Window Rules Configuration
_: {
  window-rules = [
    {
      matches = [
        {
          app-id = "^displaycal$";
        }
      ];
      default-column-width = { };
      open-floating = true;
    }
    # Disable shadows for notifications (SwayNC)
    # Fixes background "spilling out" beyond borders issue
    {
      matches = [
        { app-id = "^org\\.erikreider\\.swaync.*"; }
      ];
      shadow.enable = false;
    }
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
    # Opens maximized for optimal gaming experience
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
    # Performance tip: Disable compositor effects on this workspace if needed
    {
      matches = [
        { app-id = "^steam_app_.*"; }
      ];
      open-fullscreen = true;
      open-on-workspace = "9";
    }
  ];
}
