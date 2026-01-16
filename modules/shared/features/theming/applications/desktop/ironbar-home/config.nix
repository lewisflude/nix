# Ironbar Configuration Generator
# Generates config.json structure with all widgets from design spec
{ pkgs, lib, ... }:
let
  tokens = import ./tokens.nix { };
  commands = tokens.commands pkgs;
  widgets = import ./widgets.nix { inherit lib pkgs tokens; };

  # Widget Definitions
  # Extracted for clarity, maintainability, and conditional inclusion
  widgetDefs = {
    # 1. Layout Indicator - Shows current Niri window layout mode
    layoutIndicator = widgets.mkScriptWidget {
      name = "layout-indicator";
      class = "niri-layout control-button";
      cmd = commands.niri.layoutMode;
      tooltip = "Window Layout Mode";
    };

    # 2. Brightness Control - Interactive brightness adjustment
    brightness = widgets.mkControlWidget {
      type = "brightness";
      name = "brightness";
      format = "${tokens.icons.glyphs.brightness} {percent}%";
      interactions = {
        on_click_left = commands.brightness.decrease;
        on_click_right = commands.brightness.increase;
        on_click_middle = commands.brightness.reset;
      };
      tooltip = "Brightness: {percent}%\nLeft click: -5% | Right click: +5% | Middle: Reset to 50%";
    };

    # 3. Volume Control - Audio level management
    volume = widgets.mkControlWidget {
      type = "volume";
      name = "volume";
      format = "{icon} {percentage}%";
      interactions = {
        on_click_left = commands.volume.toggleMute;
        on_scroll_up = commands.volume.increaseBy "2%";
        on_scroll_down = commands.volume.decreaseBy "2%";
      };
      extraConfig = {
        icons = {
          volume_high = tokens.icons.glyphs.volume.high;
          volume_medium = tokens.icons.glyphs.volume.medium;
          volume_low = tokens.icons.glyphs.volume.low;
          muted = tokens.icons.glyphs.volume.muted;
        };
        max_volume = 100;
      };
      tooltip = "Volume: {percentage}%\nClick to mute | Scroll to adjust";
    };

    # 4. System Tray - Application indicators
    tray = {
      type = "tray";
      name = "system-tray";
      class = "tray";
      icon_size = tokens.icons.tray;
      icon_theme = "Adwaita";
    };

    # 5. Battery Indicator - Power status (laptop only)
    battery = {
      type = "upower";
      name = "battery";
      class = "battery";
      format = "{percentage}%";
      show_if = "test -e /sys/class/power_supply/BAT0";
    };

    # 6. Notifications - Notification center toggle
    notifications = widgets.mkControlWidget {
      type = "notifications";
      name = "notifications";
      class = "notifications";
      format = "";
      interactions = {
        on_click_left = commands.notifications.toggle;
      };
      extraConfig = {
        icon = tokens.icons.glyphs.bell;
        icon_size = tokens.icons.small;
        show_count = true;
      };
    };

    # 7. Clock - Time display with calendar popup
    clock = {
      type = "clock";
      name = "clock";
      class = "clock";
      format = "%H:%M";
      tooltip_format = "%A, %B %d, %Y";
      popup = {
        type = "calendar";
        format = "%A, %B %d, %Y";
      };
    };

    # 8. Power Menu - System power actions
    power = widgets.mkLauncherWidget {
      name = "power";
      class = "power control-button danger";
      cmd = commands.power.menu;
      icon = tokens.icons.glyphs.power;
      iconSize = tokens.icons.medium;
      tooltip = "Power Menu (Logout/Suspend/Reboot/Shutdown)";
    };
  };
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
    margin = lib.genAttrs [ "top" "bottom" "left" "right" ] (_: tokens.bar.margin);

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
    end = with widgetDefs; [
      layoutIndicator
      brightness
      volume
      tray
      battery
      notifications
      clock
      power
    ];
  };
}
