{
  pkgs,
  lib,
  config,
  ...
}:
let
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

  # Override onChange hooks to handle when ironbar isn't running yet
  xdg.configFile."ironbar/config.json".onChange = lib.mkForce ''
    if pgrep -x ironbar > /dev/null; then
      ${pkgs.ironbar}/bin/ironbar reload || true
    fi
  '';

  xdg.configFile."ironbar/style.css".onChange = lib.mkForce ''
    if pgrep -x ironbar > /dev/null; then
      ${pkgs.ironbar}/bin/ironbar reload || true
    fi
  '';

  programs.ironbar = {
    enable = true;
    systemd = true;
    # Use nixpkgs ironbar (v0.17.1) instead of flake package to avoid wrapGAppsHook issues
    package = pkgs.ironbar;

    config = {
      monitors.DP-1 = {
        anchor_to_edges = true;
        position = "top";
        height = 42;

        start = [
          {
            type = "workspaces";
            name_map = {
              "1" = "󰈹";
              "2" = "";
              "3" = "";
              "4" = "󰭹";
              "5" = "󰓇";
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
              muted = "󰝟";
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

    # Styles are managed by the Scientific theming system
    # See: home/common/theming/applications/ironbar.nix
    # This is a fallback if theming is disabled
    style = lib.mkDefault "";
  };
}
