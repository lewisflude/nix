{
  pkgs,
  ...
}: {
  programs.waybar = {
    enable = true;
    package = pkgs.waybar_git;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 24;
        spacing = 6;
        margin = "0";
        modules-left = [
          "hyprland/workspaces"
          "hyprland/scratchpad"
        ];
        modules-center = [
          "hyprland/window"
        ];
        modules-right = [
          "cpu"
          "memory"
          "temperature"
          "disk"
          "pulseaudio"
          "network"
          "clock"
          "idle_inhibitor"
          "power-profiles-daemon"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          sort-by-number = true;
          on-click = "activate";
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
          format-icons = {
            "1" = "󰎤";
            "2" = "󰎧";
            "3" = "󰎪";
            "4" = "󰎭";
            "5" = "󰎱";
            "urgent" = "󰂭";
            "focused" = "󰮯";
            "default" = "󰝤";
            "empty" = "󰝤";
          };
          persistent_workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
          };
        };

        "hyprland/scratchpad" = {
          format = "{icon} {count}";
          show-empty = false;
          format-icons = ["󰎚"];
          tooltip-format = "{app}: {title}";
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = true;
        };

        "clock" = {
          format = "{:%H:%M}";
          format-alt = "{:%a, %b %d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          interval = 1;
        };

        "cpu" = {
          format = " {usage}%";
          format-alt = " {avg_frequency} GHz";
          tooltip-format = "CPU: {usage}%\nFrequency: {avg_frequency} GHz\nTemperature: {temperature}°C";
          interval = 1;
          states = {
            warning = 70;
            critical = 90;
          };
        };

        "memory" = {
          format = "󰍛 {used:0.1f}GB";
          format-alt = "󰍛 {percentage}%";
          tooltip-format = "Memory: {used:0.1f}GB/{total:0.1f}GB ({percentage}%)\nSwap: {swapUsed:0.1f}GB/{swapTotal:0.1f}GB ({swapPercentage}%)\nCached: {cached:0.1f}GB\nBuffers: {buffers:0.1f}GB";
          interval = 1;
          states = {
            warning = 70;
            critical = 90;
          };
        };

        "temperature" = {
          critical-threshold = 80;
          format = "{icon} {temperatureC}°C";
          format-icons = ["󰋊" "󰋋" "󰋌" "󰋉" "󰋈"];
          tooltip-format = "CPU: {temperatureC}°C\nCritical: {criticalTemperatureC}°C\nSensor: {sensor}";
          hwmon-path = "/sys/class/hwmon/hwmon*/temp*_input";
          interval = 5;
        };

        "disk" = {
          format = "󰋊 {percentage_used}%";
          path = "/";
          interval = 30;
          tooltip-format = "Disk: {used:0.1f}GB/{total:0.1f}GB ({percentage_used}%)";
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰝟";
          format-icons = {
            default = ["󰕿" "󰖀" "󰕾"];
          };
          tooltip-format = "{volume}%\n{format_source}";
          on-click = "pavucontrol";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        "network" = {
          format-wifi = "󰖩 {essid} ({signalStrength}%)";
          format-ethernet = "󰈁 {ipaddr}";
          format-disconnected = "󰖪";
          format-linked = "󰈁 {ifname} (No IP)";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
          tooltip-format = "{ifname} via {gwaddr}\nSignal: {signalStrength}%\nBitrate: {bitrate}\nIP: {ipaddr}\nDNS: {dns}\nUpload: {bandwidthUpBits}\nDownload: {bandwidthDownBits}";
          on-click = "nm-connection-editor";
          interval = 1;
          format-wifi-alt = "󰖩 {bandwidthUpBits} 󰕒 {bandwidthDownBits}";
          format-ethernet-alt = "󰈁 {bandwidthUpBits} 󰕒 {bandwidthDownBits}";
        };

        "idle_inhibitor" = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾪";
          };
        };

        "power-profiles-daemon" = {
          format = "{icon}";
          tooltip-format = "{profile}";
          format-icons = {
            default = "󰾆";
            performance = "󰓅";
            balanced = "󰾆";
            power-saver = "󰾅";
          };
        };

        "tray" = {
          icon-size = 16;
          padding = [0 12];
          margin = 4;
          spacing = 12;
        };
      };
    };

    style = ''
      * {
        font-family: "Iosevka Nerd Font", "Iosevka", sans-serif;
        font-size: 16px;
        font-weight: 400;
        min-height: 0;
      }

      window#waybar {
        background-color: @base;
        color: @text;
        min-height: 24px;
      }

      #workspaces button {
        color: @text;
        background-color: @surface1;
        border-radius: 4px;
        margin:4px;
        padding: 4px 24px;
      }

      #workspaces button:checked {
        color: @base;
        background-color: @mauve;
      }

      #workspaces button:hover {
        background-color: @surface2;
      }

      #workspaces button:active {
        background-color: @mauve;
        color: @base;
      }

      #workspaces button:disabled {
        color: @surface0;
        background-color: @surface1;
      }

      #cpu, #memory, #temperature, #disk, #pulseaudio, #network, #idle_inhibitor, #power-profiles-daemon, #tray, #clock, #window, #scratchpad, #tray {
        margin: 4px;
        padding: 4px 24px;
        border-radius: 4px;
        background-color: @surface0;
        min-width: 40px;
      }

      #cpu {
        color: @sapphire;
      }

      #memory {
        color: @teal;
      }

      #temperature {
        color: @peach;
      }

      #disk {
        color: @yellow;
      }

      #pulseaudio {
        color: @blue;
      }

      #network {
        color: @sky;
      }

      #idle_inhibitor {
        color: @sapphire;
      }

      #power-profiles-daemon {
        color: @green;
      }



      #clock {
        color: @mauve;
      }

      #window {
        color: @subtext1;
      }

      #scratchpad {
        color: @pink;
      }
    '';
  };
}
