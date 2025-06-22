{ config
, pkgs
, ...
}:
let
  yaziWlClipboardSrc = pkgs.fetchFromGitHub {
    owner = "grappas";
    repo = "wl-clipboard.yazi";
    rev = "c4edc4f6adf088521f11d0acf2b70610c31924f0B";
    sha256 = "sha256-jlZgN93HjfK+7H27Ifk7fs0jJaIdnOyY1wKxHz1wX2c=";
  };
in
{
  home.packages = with pkgs; [
    fuzzel
    mako
    grim
    slurp
    swappy
    lm_sensors
    mangohud
    goverlay
    piper
    cliphist
  ];
  programs = {
    yazi = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        manager = {
          show_hidden = true;
        };
        preview = {
          max_width = 1000;
          max_height = 1000;
        };
      };
      plugins = {
        wl-clipboard = yaziWlClipboardSrc;
      };
      keymap = {
        manager.prepend_keymap = [{
          on = "<C-y>";
          run = [
            "shell -- for path in \"$@\"; do echo \"file://$path\"; done | wl-copy -t text/uri-list"
            "yank"
          ];
        }];
      };
    };
    hyprlock = {
      enable = true;
      settings = {
        background = [
          {
            path = "${config.home.sessionVariables.WALLPAPER_DIR}/nurburgring.png";
          }
        ];
      };
    };

    fuzzel = {
      enable = true;
      settings = {
        main = {
          font = "Iosevka:size=12";
          terminal = "ghostty -e";
          layer = "overlay";
          width = 30;
          horizontal-pad = 20;
          vertical-pad = 15;
          inner-pad = 5;
          launch-prefix = "uwsm app --";
          lines = 15;
          line-height = 20;
          letter-spacing = 0;
          image-size-ratio = 0.5;
          prompt = "> ";
          indicator-radius = 0;
          tabs = 4;
          icons-enabled = true;
          fuzzy = true;
          drun-launch = true;
        };

        border = {
          width = 2;
          radius = 10;
        };
        dmenu = {
          exit-immediately-if-empty = true;
        };
        key-bindings = {
          cancel = "Escape Control+g";
          execute = "Return KP_Enter Control+y";
          execute-or-next = "Tab";
          cursor-left = "Left Control+b";
          cursor-right = "Right Control+f";
          cursor-home = "Home Control+a";
          cursor-end = "End Control+e";
          delete-prev = "BackSpace";
          delete-next = "Delete";
          delete-line = "Control+k";
          prev = "Up Control+p";
          next = "Down Control+n";
          first = "Home";
          last = "End";
          page-prev = "Page_Up";
          page-next = "Page_Down";
        };
      };
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
        # preload = [ "${config.home.sessionVariables.WALLPAPER_DIR}/nix-black-4k.png" ];
        # wallpaper = ",${config.home.sessionVariables.WALLPAPER_DIR}/nix-black-4k.png";
        # "wallpaper DP-1,fit" = "${config.home.sessionVariables.WALLPAPER_DIR}/nix-black-4k.png";
        preload = [ "${config.home.sessionVariables.WALLPAPER_DIR}/nurburgring.png" ];
        wallpaper = ",${config.home.sessionVariables.WALLPAPER_DIR}/nurburgring.png";
        "wallpaper DP-1,fit" = "${config.home.sessionVariables.WALLPAPER_DIR}/nurburgring.png";
      };
    };
  };
}

