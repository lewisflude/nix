# Ironbar Configuration Generator
# Generates config.json structure with all widgets from design spec
{ pkgs, lib, ... }:
let
  tokens = import ./tokens.nix { };
  commands = tokens.commands pkgs;
  widgets = import ./widgets.nix { inherit lib pkgs tokens; };
in
{
  # Bar configuration for Relaxed profile (1440p+)
  # Following design spec structure: Start Island, Center Island, End Island
  config = {
    # Bar dimensions and positioning
    position = "top";
    height = tokens.bar.height;
    anchor_to_edges = true;

    # Margin synchronized with Niri layout gaps
    margin = {
      top = tokens.bar.margin;
      bottom = tokens.bar.margin;
      left = tokens.bar.margin;
      right = tokens.bar.margin;
    };

    # Layer shell configuration
    layer = "top";
    exclusive_zone = true;

    # Popup configuration
    popup_gap = 5;
    popup_autohide = false;

    # Start Island - Workspaces Widget
    start = [
      {
        type = "workspaces";
        name = "workspaces";
        class = "workspaces";

        # Widget-specific options
        all_monitors = false; # Only show workspaces for current monitor
        sort = "id"; # Sort by workspace ID
        hide_empty = false; # Show all workspaces

        # Icon configuration - using centralized workspace icons
        icons = tokens.icons.glyphs.workspace;

        # Niri integration
        compositor = "niri";
      }
    ];

    # Center Island - Window Title Widget
    center = [
      {
        type = "focused";
        name = "window-title";
        class = "focused";

        # Display settings
        show_icon = true;
        show_title = true;
        icon_size = tokens.icons.small;

        # Truncation (max 50 characters per design spec)
        truncate = {
          mode = "end"; # Ellipsis at end
          length = tokens.widgets.window-title.max-chars;
        };
      }
    ];

    # End Island - Status Widgets (ordered deliberately per design spec)
    end = [
      # 1. Layout Indicator Widget
      (widgets.mkScriptWidget {
        name = "layout-indicator";
        class = "niri-layout control-button";
        cmd = commands.niri.layoutMode;
        tooltip = "Window Layout Mode";
      })

      # 2. Brightness Control Widget
      (widgets.mkControlWidget {
        type = "brightness";
        name = "brightness";
        format = "${tokens.icons.glyphs.brightness} {percent}%";
        interactions = {
          on_click_left = commands.brightness.decrease;
          on_click_right = commands.brightness.increase;
          on_click_middle = commands.brightness.reset;
        };
        tooltip = "Brightness: {percent}%\nLeft click: -5% | Right click: +5% | Middle: Reset to 50%";
      })

      # 3. Volume Control Widget
      (widgets.mkControlWidget {
        type = "volume";
        name = "volume";
        format = "{icon} {percentage}%";
        interactions = {
          on_click_left = commands.volume.toggleMute;
          on_scroll_up = commands.volume.increaseBy "2%";
          on_scroll_down = commands.volume.decreaseBy "2%";
        };
        extraConfig = {
          # Icon mapping based on volume level
          icons = {
            volume_high = tokens.icons.glyphs.volume.high;
            volume_medium = tokens.icons.glyphs.volume.medium;
            volume_low = tokens.icons.glyphs.volume.low;
            muted = tokens.icons.glyphs.volume.muted;
          };
          max_volume = 100;
        };
        tooltip = "Volume: {percentage}%\nClick to mute | Scroll to adjust";
      })

      # 4. System Tray Widget
      {
        type = "tray";
        name = "system-tray";
        class = "tray";

        # Icon configuration
        icon_size = tokens.icons.tray;
        icon_theme = "Adwaita"; # Fallback theme

        # Spacing between items handled by CSS
      }

      # 5. Battery Indicator Widget (conditional on hardware)
      {
        type = "upower";
        name = "battery";
        class = "battery";

        # Display format (percentage only)
        format = "{percentage}%";

        # Show only when battery is present
        show_if = "test -e /sys/class/power_supply/BAT0";
      }

      # 6. Notification Button Widget
      (widgets.mkControlWidget {
        type = "notifications";
        name = "notifications";
        class = "notifications";
        format = ""; # Handled by widget internally
        interactions = {
          on_click_left = commands.notifications.toggle;
        };
        extraConfig = {
          icon = tokens.icons.glyphs.bell;
          icon_size = tokens.icons.small;
          show_count = true;
        };
      })

      # 7. Clock Widget
      {
        type = "clock";
        name = "clock";
        class = "clock";

        # Time format (24-hour, HH:MM)
        format = "%H:%M";

        # Tooltip with full date
        tooltip_format = "%A, %B %d, %Y";

        # Popup configuration
        popup = {
          type = "calendar";
          format = "%A, %B %d, %Y";
        };
      }

      # 8. Power Button Widget
      (widgets.mkLauncherWidget {
        name = "power";
        class = "power control-button danger";
        cmd = commands.power.menu;
        icon = tokens.icons.glyphs.power;
        iconSize = tokens.icons.medium;
        tooltip = "Power Menu (Logout/Suspend/Reboot/Shutdown)";
      })
    ];
  };
}
