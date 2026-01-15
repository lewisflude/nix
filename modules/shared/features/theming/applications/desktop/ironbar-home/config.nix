# Ironbar Configuration Generator
# Generates config.json structure with all widgets from design spec
{ pkgs, lib, ... }:
let
  tokens = import ./tokens.nix { };
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

        # Icon configuration - using circled Unicode numbers ①-⑩
        icons = {
          "1" = "①";
          "2" = "②";
          "3" = "③";
          "4" = "④";
          "5" = "⑤";
          "6" = "⑥";
          "7" = "⑦";
          "8" = "⑧";
          "9" = "⑨";
          "10" = "⑩";
        };

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
      {
        type = "script";
        name = "layout-indicator";
        class = "niri-layout control-button";

        # Poll niri for layout mode
        cmd = "${pkgs.niri-unstable}/bin/niri msg focused-window | ${pkgs.jq}/bin/jq -r '.layout_mode // \"tiled\"'";
        mode = "poll";
        interval = 1000;

        # Format output with appropriate icon
        format = "{output}";

        # Map layout modes to icons
        # Note: Icon mapping handled via script output or custom formatting
        tooltip = "Window Layout Mode";
      }

      # 2. Brightness Control Widget
      {
        type = "brightness";
        name = "brightness";
        class = "brightness control-button";

        # Display format
        format = "󰃠 {percent}%";

        # Interaction
        on_click_left = "${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
        on_click_right = "${pkgs.brightnessctl}/bin/brightnessctl set +5%";
        on_click_middle = "${pkgs.brightnessctl}/bin/brightnessctl set 50%";

        tooltip = "Brightness: {percent}%\nLeft click: -5% | Right click: +5% | Middle: Reset to 50%";
      }

      # 3. Volume Control Widget
      {
        type = "volume";
        name = "volume";
        class = "volume control-button";

        # Display format with dynamic icon
        format = "{icon} {percentage}%";

        # Icon mapping based on volume level
        icons = {
          volume_high = "󰕾"; # > 66%
          volume_medium = "󰖀"; # 33-66%
          volume_low = "󰕿"; # 1-32%
          muted = "󰝟"; # 0% or muted
        };

        # Max volume cap
        max_volume = 100;

        # Interaction
        on_click_left = "{{${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle}}";
        on_scroll_up = "{{${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+}}";
        on_scroll_down = "{{${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-}}";

        tooltip = "Volume: {percentage}%\nClick to mute | Scroll to adjust";
      }

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
      {
        type = "notifications";
        name = "notifications";
        class = "notifications";

        # Icon configuration
        icon = ""; # Bell icon (nerd font)
        icon_size = tokens.icons.small;

        # Show notification count
        show_count = true;

        # Integration with swaync
        on_click_left = "${pkgs.swaynotificationcenter}/bin/swaync-client -t";
      }

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
      {
        type = "launcher";
        name = "power";
        class = "power control-button danger";

        # Power icon
        icon = ""; # Power icon (nerd font)
        icon_size = tokens.icons.medium;

        # Launch power menu using fuzzel
        # Power menu options: Logout, Suspend, Hibernate, Reboot, Shutdown
        cmd = ''
          echo -e "Logout\nSuspend\nHibernate\nReboot\nShutdown" | \
          ${pkgs.fuzzel}/bin/fuzzel --dmenu | \
          ${pkgs.gnused}/bin/sed \
            -e 's/^Logout$/loginctl terminate-user $USER/' \
            -e 's/^Suspend$/systemctl suspend/' \
            -e 's/^Hibernate$/systemctl hibernate/' \
            -e 's/^Reboot$/systemctl reboot/' \
            -e 's/^Shutdown$/systemctl poweroff/' | \
          sh
        '';

        tooltip = "Power Menu (Logout/Suspend/Reboot/Shutdown)";
      }
    ];
  };
}
