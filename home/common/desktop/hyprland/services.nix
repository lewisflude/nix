{ config, ... }:
{
  programs.hyprlock = {
    enable = true;
    settings = {
      background = [
        {
          path = "${config.home.sessionVariables.WALLPAPER_DIR}/nurburgring.png";
        }
      ];
    };
  };

  services = {
    hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }

          {
            timeout = 420;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };

    hyprpaper = {
      enable = true;
      settings = {
        ipc = true;
        preload = [ "${config.home.sessionVariables.WALLPAPER_DIR}/nurburgring.png" ];
        wallpaper = ",${config.home.sessionVariables.WALLPAPER_DIR}/nurburgring.png";
        "wallpaper DP-1,fit" = "${config.home.sessionVariables.WALLPAPER_DIR}/nurburgring.png";
      };
    };
  };
}