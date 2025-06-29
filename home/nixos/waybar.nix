{ pkgs, config, ... }:
let
  # Workspace icons mapping for maintainability (Iosevka Nerd Font)
  workspaceIcons = {
    "1" = ""; # Browser
    "2" = ""; # Terminal
    "3" = ""; # Code
    "4" = ""; # Music
    "5" = ""; # Chat
    default = ""; # Unknown
  };
in
{
  programs.waybar = {
    enable = true;
    package = pkgs.waybar_git;
    style = ./style.css;

    settings = {
      mainBar = {
        log-level = 3;
        output = [ "DP-1" ];

        # Left-aligned modules
        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];

        # Right-aligned modules (with custom progress & alerts)
        modules-right = [
          "network"
          "cpu"
          "memory"
          "custom/backup"
          "custom/alerts"
          "custom/brightness"
          "pulseaudio"
          "clock"
        ];

        # Workspace icons
        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = workspaceIcons;
          on-click = "activate";
          persistent-workspaces = {
            "*" = 5;
          };
        };

        # Active window title
        "hyprland/window" = {
          format = "{title}";
        };

        # Network status
        network = {
          format = " {ifname} {ipaddr}/{cidr}";
          format-wifi = " {essid} ({signalStrength}%)";
          format-ethernet = " {ifname}";
          tooltip-format = "{ifname} via {gwaddr}\n{ipaddr}/{cidr}\nUp: {bandwidthUpBits}bps\nDown: {bandwidthDownBits}bps";
          interval = 5;
          on-click = "nm-connection-editor";
        };

        # CPU usage (with CSS alert support)
        cpu = {
          format = " {usage}%";
          tooltip-format = "CPU: {usage}%\nLoad: {load}";
          interval = 2;
          on-click = "ghostty -e btop";
          format-alt = "{usage}";
        };

        # Memory usage (with CSS alert support)
        memory = {
          format = " {used:0.1f}G/{total:0.1f}G";
          tooltip-format = "Memory: {used:0.1f}G / {total:0.1f}G\nAvailable: {avail:0.1f}G";
          interval = 5;
          on-click = "ghostty -e btop";
          format-alt = "{used_percent}";
        };

        # Backup progress module
        "custom/backup" = {
          exec = "${config.home.homeDirectory}/bin/backup-status";
          return-type = "json";
          interval = 30;
          format = " {percentage}%";
          tooltip-format = "Backup: {percentage}% complete";
        };

        # Load-sparkline alerts
        "custom/alerts" = {
          exec = "${config.home.homeDirectory}/bin/system-spark";
          interval = 10;
          format = "{spark}";
          tooltip-format = "Load history: {loadHistory}";
        };

        # Brightness control
        "custom/brightness" = {
          exec = "/home/lewis/.nix-profile/bin/brightness get";
          format = " {}%";
          tooltip = false;
          interval = 30;
          on-click = "/home/lewis/.nix-profile/bin/brightness set 100";
          on-click-right = "/home/lewis/.nix-profile/bin/brightness set 0";
          on-scroll-up = "/home/lewis/.nix-profile/bin/brightness up";
          on-scroll-down = "/home/lewis/.nix-profile/bin/brightness down";
        };

        # Audio volume
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
          on-click = "pavucontrol";
        };

        # Clock and calendar
        clock = {
          format = " {:%a %d %b %H:%M}";
          tooltip-format = "{:%A, %d %B %Y | %H:%M:%S}";
          interval = 60;
          on-click = "gsimplecal";
        };
      };
    };
  };

  # Brightness helper script (unchanged)
  home.file."bin/brightness" = {
    text = ''
      #!/usr/bin/env bash
      CACHE_FILE="/tmp/brightness_cache"
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

  # Backup-status helper script
  home.file."bin/backup-status" = {
    text = ''
      #!/usr/bin/env bash
      HOME_DIR="$HOME"
      stats=$(rsync --dry-run --stats "$HOME_DIR/data/" /backup/ 2>/dev/null)
      transferred=$(awk '/Number of files transferred/ {print $NF}' <<<"$stats")
      total=$(awk '/Total file size/ {print $NF}' <<<"$stats")
      if (( total > 0 )); then pct=$((100 * transferred / total)); else pct=100; fi
      echo "{\"percentage\":$pct}"
    '';
    executable = true;
  };

  # System-spark helper script
  home.file."bin/system-spark" = {
    text = ''
      #!/usr/bin/env bash
      IFS=',' read -r load1 load5 load15 _ < <(uptime | sed -E 's/.*load average: //')
      spark=""
      for load in $load1 $load5 $load15; do
        lv=$(echo "$load" | awk '{printf "%d", $1*10}')
        if (( lv >= 20 )); then spark+=▇;
        elif (( lv >= 10 )); then spark+=▅;
        elif (( lv >= 5 )); then spark+=▂;
        else spark+=▁; fi
      done
      echo "{\"spark\":\"$spark\",\"loadHistory\":\"$load1,$load5,$load15\"}"
    '';
    executable = true;
  };
}
