{
  pkgs,
  config,
  ...
}: let
  workspaceIcons = {
    "1" = "";
    "2" = "";
    "3" = "";
    "4" = "";
    "5" = "";
    default = "";
  };
  uwsm = "${pkgs.uwsm}/bin/uwsm";
  ghostty = "${pkgs.ghostty}/bin/ghostty";
in {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    package = pkgs.waybar-git;
    style = ./style.css;
    settings = {
      mainBar = {
        log-level = 3;
        layer = "top";
        position = "top";
        output = ["DP-1"];
        modules-left = [
          "niri/workspaces"
          "niri/window"
        ];
        modules-right = [
          "network"
          "cpu"
          "memory"
          "custom/backup"
          "custom/alerts"
          "custom/brightness"
          "idle_inhibitor"
          "pulseaudio"
          "clock"
          "tray"
          "custom/notifications"
        ];
        "niri/workspaces" = {
          format = "{icon}";
          format-icons = workspaceIcons;
          on-click = "activate";
          persistent-workspaces = {
            "*" = 5;
          };
        };
        "niri/window" = {
          format = "{title}";
        };
        network = {
          format = " {ifname} {ipaddr}/{cidr}";
          format-wifi = " {essid} ({signalStrength}%)";
          format-ethernet = " {ifname}";
          tooltip-format = "{ifname} via {gwaddr}\n{ipaddr}/{cidr}\nUp: {bandwidthUpBits}bps\nDown: {bandwidthDownBits}bps";
          interval = 5;
          on-click = "${uwsm} app -- nm-connection-editor";
        };
        cpu = {
          format = " {usage}%";
          tooltip-format = "CPU: {usage}%\nLoad: {load}";
          interval = 2;
          on-click = "${uwsm} app -- ${ghostty} -e btop";
          format-alt = "{usage}";
        };
        memory = {
          format = " {used:0.1f}G/{total:0.1f}G";
          tooltip-format = "Memory: {used:0.1f}G / {total:0.1f}G\nAvailable: {avail:0.1f}G";
          interval = 5;
          on-click = "${uwsm} app -- ${ghostty} -e btop";
          format-alt = "{used_percent}";
        };
        "custom/backup" = {
          exec = "${config.home.homeDirectory}/bin/backup-status";
          return-type = "json";
          interval = 30;
          format = " {percentage}%";
          tooltip-format = "Backup: {percentage}% complete";
        };
        "custom/alerts" = {
          exec = "${config.home.homeDirectory}/bin/system-spark-percentage";
          return-type = "json";
          interval = 10;
          format = "{icon}";
          format-icons = {
            "default" = "▁▁▁";
            "low" = "▂▂▂";
            "medium" = "▅▅▅";
            "high" = "▇▇▇";
          };
        };
        "custom/brightness" = {
          exec = "${config.home.homeDirectory}/bin/brightness get";
          format = " {}%";
          tooltip = false;
          interval = 30;
          on-click = "${config.home.homeDirectory}/bin/brightness set 100";
          on-click-right = "${config.home.homeDirectory}/bin/brightness set 0";
          on-scroll-up = "${config.home.homeDirectory}/bin/brightness up";
          on-scroll-down = "${config.home.homeDirectory}/bin/brightness down";
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "☕";
            deactivated = "😴";
          };
          tooltip-format-activated = "Staying awake - screen won't sleep (click to disable)";
          tooltip-format-deactivated = "Screen can sleep (click to keep awake)";
        };
        tray = {
          icon-size = 24;
          spacing = 10;
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-icons = [
            "ﱝ"
            ""
            ""
            ""
          ];
          tooltip-format = "Device: {desc}\nVolume: {volume}%";
          scroll-step = 5;
          on-click = "pwvucontrol";
        };
        "custom/notifications" = {
          tooltip = false;
          format = "{icon}";
          format-icons = {
            "notification" = "<span foreground='red'><sup></sup></span>";
            "none" = "";
            "dnd-notification" = "<span foreground='red'><sup></sup></span>";
            "dnd-none" = "";
            "inhibited-notification" = "<span foreground='red'><sup></sup></span>";
            "inhibited-none" = "";
            "dnd-inhibited-notification" = "<span foreground='red'><sup></sup></span>";
            "dnd-inhibited-none" = "";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
        };
        clock = {
          format = "  {:%a %d %b %H:%M}";
          tooltip-format = "{:%A, %d %B %Y | %H:%M:%S}";
          interval = 60;
          on-click = "${uwsm} app -- gsimplecal";
        };
      };
    };
  };
  home.file = {
    "bin/brightness" = {
      text = ''
        CACHE_FILE="$HOME/.config/niri/last_brightness"
        mkdir -p "$(dirname "$CACHE_FILE")"
        case "$1" in
          get)
            if [ -f "$CACHE_FILE" ]; then
              cat "$CACHE_FILE"
            else
              brightness=$(timeout 2 ddcutil getvcp 10 --brief 2>/dev/null | awk '{print $4}' || echo "50")
              echo "$brightness" | tee "$CACHE_FILE"
            fi
            ;;
          up)
            current=$(cat "$CACHE_FILE" 2>/dev/null || echo "50")
            new=$((current + 5)); [ $new -gt 100 ] && new=100
            echo "$new" | tee "$CACHE_FILE"
            nohup timeout 3 ddcutil setvcp 10 "$new" --brief >/dev/null 2>&1 &
            ;;
          down)
            current=$(cat "$CACHE_FILE" 2>/dev/null || echo "50")
            new=$((current - 5)); [ $new -lt 0 ] && new=0
            echo "$new" | tee "$CACHE_FILE"
            nohup timeout 3 ddcutil setvcp 10 "$new" --brief >/dev/null 2>&1 &
            ;;
          set)
            echo "$2" | tee "$CACHE_FILE"
            nohup timeout 3 ddcutil setvcp 10 "$2" --brief >/dev/null 2>&1 &
            ;;
        esac
      '';
      executable = true;
    };
    "bin/backup-status" = {
      text = ''
        HOME_DIR="$HOME"
        stats=$(rsync --dry-run --stats "$HOME_DIR/data/" /backup/ 2>/dev/null)
        transferred=$(awk '/Number of files transferred/ {print $NF}' <<<"$stats")
        total=$(awk '/Total file size/ {print $NF}' <<<"$stats")
        if (( total > 0 )); then pct=$((100 * transferred / total)); else pct=100; fi
        echo "{\"percentage\":$pct}"
      '';
      executable = true;
    };
    "bin/system-spark-percentage" = {
      text = ''
        IFS=',' read -r load1 load5 load15 _ < <(uptime | sed -E 's/.*load average: //')
        load_pct=$(echo "$load1" | awk '{printf "%d", ($1/2.0)*100}')
        if [ $load_pct -gt 100 ]; then load_pct=100; fi
        if [ $load_pct -ge 80 ]; then
          alt="high"
        elif [ $load_pct -ge 50 ]; then
          alt="medium"
        elif [ $load_pct -ge 25 ]; then
          alt="med-low"
        else
          alt="low"
        fi
        printf '{"percentage":%d,"alt":"%s"}' "$load_pct" "$alt" | jq --unbuffered --compact-output
      '';
      executable = true;
    };
  };
}
