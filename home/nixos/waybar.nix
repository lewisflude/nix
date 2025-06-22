{ pkgs, ... }: {
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
    
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 4;
        
        # Module layout
        modules-left = [
          "hyprland/workspaces"
          "hyprland/scratchpad"
          "hyprland/window"
        ];
        
        modules-center = [
          "clock"
        ];
        
        modules-right = [
          "tray"
          "cpu"
          "memory"
          "temperature"
          "network"
          "pulseaudio"
          "battery"
          "custom/power"
        ];
        
        # Module configurations
        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "󰨞";  # Terminal/Development
            "2" = "󰇩";  # Web browser
            "3" = "󰙯";  # Communication
            "4" = "󰝚";  # Entertainment/Music
            "5" = "󰦬";  # Productivity/Notes
            "6" = "󰀨";  # File management
            "7" = "󰖟";  # Graphics/Design
            "8" = "󰚀";  # Virtual machines
            "9" = "󰍉";  # Monitoring/System
            "magic" = "󰓏";  # Special workspace
            "gaming" = "󰊖";  # Gaming workspace
          };
          on-click = "activate";
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
          sort-by-number = true;
          persistent-workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
          };
        };
        
        "hyprland/scratchpad" = {
          format = "{icon} {count}";
          format-icons = ["" "󰅌"];
          tooltip = true;
          tooltip-format = "{app}: {title}";
          show-empty = false;
        };
        
        "hyprland/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = true;
        };
        
        "clock" = {
          format = "{:%H:%M}";
          format-alt = "{:%A, %B %d, %Y (%R)}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-click-forward = "tz_up";
            on-click-backward = "tz_down";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };
        
        "cpu" = {
          format = " {usage}%";
          tooltip = false;
          on-click = "ghostty -e btop";
        };
        
        "memory" = {
          format = " {}%";
          tooltip-format = "Memory: {used:0.1f}G/{total:0.1f}G ({percentage}%)\\nSwap: {swapUsed:0.1f}G/{swapTotal:0.1f}G ({swapPercentage}%)";
          on-click = "ghostty -e btop";
        };
        
        "temperature" = {
          thermal-zone = 2;
          hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
          critical-threshold = 80;
          format-critical = " {temperatureC}°C";
          format = " {temperatureC}°C";
        };
        
        "network" = {
          format-wifi = " {essid} ({signalStrength}%)";
          format-ethernet = "󰈀 {ipaddr}/{cidr}";
          tooltip-format = "󰈀 {ifname} via {gwaddr}";
          format-linked = "󰈀 {ifname} (No IP)";
          format-disconnected = "⚠ Disconnected";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
          on-click-right = "nm-connection-editor";
        };
        
        "pulseaudio" = {
          scroll-step = 5;
          format = "{icon} {volume}%";
          format-bluetooth = "{icon} {volume}% 󰂯";
          format-bluetooth-muted = "󰝟 󰂯";
          format-muted = "󰝟";
          format-source = " {volume}%";
          format-source-muted = "";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󰋎";
            headset = "󰋎";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
          on-click-right = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
          on-scroll-up = "pactl set-sink-volume @DEFAULT_SINK@ +5%";
          on-scroll-down = "pactl set-sink-volume @DEFAULT_SINK@ -5%";
        };
        
        "battery" = {
          states = {
            good = 95;
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰂄 {capacity}%";
          format-alt = "{icon} {time}";
          format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
        };
        
        "tray" = {
          icon-size = 21;
          spacing = 10;
        };
        
        "custom/power" = {
          format = "⏻";
          tooltip = false;
          on-click = "wlogout";
        };
      };
    };
    
    style = ''
      * {
        font-family: "Iosevka Nerd Font", "Font Awesome 6 Free";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: rgba(36, 39, 58, 0.8);
        border-bottom: 3px solid rgba(183, 189, 248, 0.8);
        color: #cad3f5;
        transition-property: background-color;
        transition-duration: 0.5s;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      #workspaces {
        background-color: rgba(30, 32, 48, 0.8);
        margin: 4px 4px 4px 8px;
        padding: 0 4px;
        border-radius: 8px;
      }

      #workspaces button {
        padding: 0 8px;
        background-color: transparent;
        color: #6e738d;
        border: none;
        border-radius: 8px;
      }

      #workspaces button:hover {
        background-color: rgba(91, 96, 120, 0.5);
        box-shadow: inset 0 -3px #cad3f5;
        color: #cad3f5;
      }

      #workspaces button.active {
        background-color: rgba(139, 173, 244, 0.3);
        color: #8aadf4;
      }

      #workspaces button.urgent {
        background-color: rgba(237, 135, 150, 0.5);
        color: #ed8796;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #temperature,
      #network,
      #pulseaudio,
      #custom-power,
      #tray,
      #scratchpad,
      #window {
        background-color: rgba(30, 32, 48, 0.8);
        padding: 0 12px;
        margin: 4px 2px;
        border-radius: 8px;
        color: #cad3f5;
      }

      #window {
        font-weight: bold;
        max-width: 300px;
      }

      #clock {
        color: #8aadf4;
        font-weight: bold;
      }

      #cpu {
        color: #8bd5ca;
      }

      #memory {
        color: #c6a0f6;
      }

      #temperature {
        color: #f5a97f;
      }

      #temperature.critical {
        color: #ed8796;
      }

      #network {
        color: #a6da95;
      }

      #network.disconnected {
        color: #ed8796;
      }

      #pulseaudio {
        color: #f4dbd6;
      }

      #pulseaudio.muted {
        color: #6e738d;
      }

      #battery {
        color: #a6da95;
      }

      #battery.charging, #battery.plugged {
        color: #8aadf4;
      }

      #battery.critical:not(.charging) {
        color: #ed8796;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      @keyframes blink {
        to {
          background-color: #ed8796;
          color: #24273a;
        }
      }

      #custom-power {
        color: #ed8796;
        font-size: 16px;
        margin-right: 8px;
      }

      #custom-power:hover {
        background-color: rgba(237, 135, 150, 0.2);
      }

      #tray {
        background-color: rgba(30, 32, 48, 0.8);
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #ed8796;
      }

      #scratchpad {
        color: #eed49f;
      }

      #scratchpad.empty {
        background-color: transparent;
      }
    '';
  };
}