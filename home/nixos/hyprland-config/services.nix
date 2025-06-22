{ config, ... }:
{
  services = {
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