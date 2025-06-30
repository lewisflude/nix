{ config, ... }:
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 300;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = [
        {
          path = "${config.home.homeDirectory}/wallpapers/nix-wallpaper-nineish-catppuccin-mocha.png";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = ''<span foreground="##cad3f5">Password...</span>'';
          shadow_passes = 2;
        }
      ];

      label = [
        {
          text = "cmd[update:1000] echo \"$TIME\"";
          color = "rgb(202, 211, 245)";
          font_size = 55;
          font_family = "Iosevka Nerd Font";
          position = "0, 160";
          halign = "center";
          valign = "center";
        }
        {
          text = "Hi there, $USER";
          color = "rgb(202, 211, 245)";
          font_size = 20;
          font_family = "Iosevka Nerd Font";
          position = "0, 0";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
