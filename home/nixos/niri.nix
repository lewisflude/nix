{ pkgs, config, ... }:
let
  # Default applications
  terminal = "ghostty";
  launcher = "fuzzel";
  screenLocker = "swaylock";
in
{
  home.packages = with pkgs; [
    swww
    swaylock
  ];

  imports = [
    ./niri/keybinds.nix
  ];

  programs.niri = {
    package = pkgs.niri-unstable;
    settings = {

      outputs = {
        "DP-1" = {
          position = {
            x = 0;
            y = 0;
          };
          mode = {
            width = 3440;
            height = 1440;
            refresh = 165.00;
          };
          scale = 1.25;
          variable-refresh-rate = true;
        };
      };

      environment = {
        DISPLAY = ":0";
        NIXOS_OZONE_WL = "1";

        ELECTRON_OZONE_PLATFORM_HINT = "auto";

        _JAVA_AWT_WM_NONREPARENTING = "1";

        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "gtk3";

        XDG_CURRENT_DESKTOP = "niri";
        XDG_SESSION_DESKTOP = "niri";
        XDG_SESSION_TYPE = "wayland";
      };
      xwayland-satellite = {
        enable = true;
        path = "${pkgs.xwayland-satellite-unstable}/bin/xwayland-satellite";
      };
      binds = {
        "Mod+T" = {
          action.spawn = [ terminal ];
        };
        "Mod+D" = {
          action.spawn = [ launcher ];
        };
        "Super+Alt+L" = {
          action.spawn = [ screenLocker ];
        };
      };

      spawn-at-startup = [
        {
          command = [
            "uwsm app -- ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

            "systemctl enable - -user com.mitchellh.ghostty.service"
            "uwsm app -- swaylock"
            "uwsm app -- swww-daemon"
            "swww img ${config.home.homeDirectory}/wallpapers/nix-wallpaper-nineish-catppuccin-mocha.png"
            "pw-link 'Main-Output-Proxy:monitor_FL' 'alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX0'"
            "pw-link 'Main-Output-Proxy:monitor_FR' 'alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX1'"
          ];
        }
      ];
    };
  };
}
