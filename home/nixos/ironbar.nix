{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  catppuccinPalette =
    if lib.hasAttrByPath [ "catppuccin" "sources" "palette" ] config then
      (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
      .${config.catppuccin.flavor}.colors
    else if inputs ? catppuccin then
      let
        catppuccinSrc = inputs.catppuccin.src or inputs.catppuccin.outPath or null;
      in
      if catppuccinSrc != null then
        (pkgs.lib.importJSON (catppuccinSrc + "/palette.json")).mocha.colors
      else
        throw "Cannot find catppuccin source"
    else
      throw "Cannot find catppuccin input";

  brightnessScript = pkgs.writeShellApplication {
    name = "brightness";
    runtimeInputs = with pkgs; [
      coreutils
      ddcutil
    ];
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
  };
in
{
  home.packages = [ brightnessScript ];

  programs.ironbar = {
    enable = true;
    systemd = true;

    config = {
      monitors.DP-1 = {
        anchor_to_edges = true;
        position = "top";
        height = 42;
        
        start = [
        {
          type = "workspaces";
          name_map = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
          };
        }
        {
          type = "label";
          label = "{{window_title}}";
        }
      ];

      end = [
        {
          type = "sys_info";
          format = [
            " {cpu_percent}%"
            " {memory_used_gb}/{memory_total_gb}GB"
          ];
          interval = 2000;
        }
        {
          type = "custom";
          class = "brightness";
          exec = "${lib.getExe brightnessScript} get";
          interval = 30000;
          format = " {}%";
          on_click_left = "${lib.getExe brightnessScript} set 100";
          on_click_right = "${lib.getExe brightnessScript} set 0";
          on_scroll_up = "${lib.getExe brightnessScript} up";
          on_scroll_down = "${lib.getExe brightnessScript} down";
        }
        {
          type = "volume";
          format = "{icon} {percentage}%";
          icons = {
            volume_high = "";
            volume_medium = "";
            volume_low = "";
            muted = "?";
          };
          on_click = "pwvucontrol";
        }
        {
          type = "clock";
          format = "  %a %d %b %H:%M";
          on_click = "${pkgs.uwsm}/bin/uwsm app -- gsimplecal";
        }
        {
          type = "tray";
          icon_size = 24;
        }
        {
          type = "custom";
          class = "notifications";
          exec = "swaync-client -swb";
          return_type = "json";
          interval = 1000;
          format = "{icon}";
          on_click = "swaync-client -t -sw";
          on_click_right = "swaync-client -d -sw";
        }
      ];
      };
    };

    style = ''
      * {
        font-family: "Iosevka Nerd Font", "Font Awesome 6 Free", sans-serif;
        font-size: 14px;
        border: none;
      }

      #bar {
        background-color: #${catppuccinPalette.base.hex};
        color: #${catppuccinPalette.text.hex};
      }

      #workspaces button {
        padding: 0 10px;
        background-color: transparent;
        color: #${catppuccinPalette.text.hex};
      }

      #workspaces button.focused {
        background-color: #${catppuccinPalette.mauve.hex};
        color: #${catppuccinPalette.base.hex};
      }

      #label,
      #sys_info,
      #clock,
      #volume,
      #tray,
      .custom,
      .brightness,
      .notifications {
        padding: 0 12px;
        margin: 0 2px;
      }

      #volume,
      #clock,
      .custom {
        background-color: #${catppuccinPalette.surface0.hex};
      }
    '';
  };
}
