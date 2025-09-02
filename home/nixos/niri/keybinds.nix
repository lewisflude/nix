{
  config,
  pkgs,
  lib,
  ghostty,
  ...
}: let
  brightness = "${config.home.homeDirectory}/bin/brightness";

  # Use lib.getExe for robust executable paths
  uwsm = lib.getExe pkgs.uwsm;
  terminal = lib.getExe ghostty.packages.${pkgs.system}.default;
  launcher = [
    uwsm
    "app"
    "--"
    (lib.getExe pkgs.fuzzel)
  ];
  screenLocker = lib.getExe pkgs.swaylock-effects;
in {
  # Packages for utilities used in keybindings
  home.packages = with pkgs; [
    hyprpicker # Wayland-native color picker
    jq # Needed for processing wcolor output
  ];

  programs.niri.settings.binds = {
    # -----------------------------------------------------------------------------
    # -- Session, Meta & Power Controls
    # -----------------------------------------------------------------------------
    "Mod+Shift+Slash".action.show-hotkey-overlay = {};

    "Mod+Escape" = {
      allow-inhibiting = false;
      action.toggle-keyboard-shortcuts-inhibit = {};
    };

    "Super+Alt+L".action.spawn = [screenLocker];

    "Mod+Shift+P".action.power-off-monitors = {};

    # KVM display recovery - force display reset
    "Mod+Shift+D" = {
      action.spawn = [
        "sh"
        "-c"
        "niri msg action power-off-monitors && sleep 2 && niri msg action power-on-monitors"
      ];
    };

    "Mod+Shift+E".action.quit = {};
    "Ctrl+Alt+Delete".action.quit = {};

    "Mod+Ctrl+Shift+R".action.spawn = [
      "niri"
      "msg"
      "action"
      "reload-config"
    ];

    "Mod+X" = {
      action.spawn = [
        "sh"
        "-c"
        ''
          OPTIONS="Logout\nSuspend\nHibernate\nReboot\nShutdown"
          CHOICE=$(echo -e "$OPTIONS" | fuzzel --dmenu --prompt 'Power:')
          case "$CHOICE" in
            Logout) niri msg action quit ;;
            Suspend) systemctl suspend ;;
            Hibernate) systemctl hibernate ;;
            Reboot) systemctl reboot ;;
            Shutdown) systemctl poweroff ;;
          esac
        ''
      ];
    };

    "Mod+Alt+S" = {
      action.spawn = [
        "systemctl"
        "suspend"
      ];
    };

    "Mod+Alt+H" = {
      action.spawn = [
        "systemctl"
        "hibernate"
      ];
    };

    # -----------------------------------------------------------------------------
    # -- Application Launchers
    # -----------------------------------------------------------------------------
    "Mod+T".action.spawn = terminal;
    "Mod+D".action.spawn = launcher;

    "Mod+V" = {
      action.spawn = [
        "sh"
        "-c"
        "cliphist list | fuzzel --dmenu | cliphist decode"
      ];
    };

    "Mod+B" = {
      action.spawn = [
        uwsm
        "app"
        "--"
        (lib.getExe pkgs.chromium)
      ];
    };

    "Mod+E".action.spawn = [
      "${ghostty.packages.${pkgs.system}.default}/bin/ghostty"
      "-e"
      "yazi"
    ];

    "Mod+Ctrl+O" = {
      action.spawn = [
        uwsm
        "app"
        "--"
        (lib.getExe pkgs.obsidian)
      ];
    };

    "Mod+Shift+O" = {
      action.spawn = [
        terminal # Use your defined terminal
        "-e"
        (lib.getExe pkgs.helix)
        "${config.home.homeDirectory}/.config/nix"
      ];
    };

    "Mod+Shift+B" = {
      action.spawn = [
        uwsm
        "app"
        "--"
        (lib.getExe pkgs.firefox)
      ];
    };

    "Mod+M" = {
      action.spawn = [
        uwsm
        "app"
        "--"
        (lib.getExe pkgs.thunderbird)
      ];
    };

    # -----------------------------------------------------------------------------
    # -- Utility Bindings (Screenshots, Color Picker, Notifications)
    # -----------------------------------------------------------------------------
    "Print" = {
      allow-inhibiting = false;
      action.spawn = [
        "sh"
        "-c"
        ''grim -g "$(slurp)" - | ${config.home.homeDirectory}/bin/swappy-fixed -f -''
      ];
    };

    "Shift+Print" = {
      allow-inhibiting = false;
      action.spawn = [
        "sh"
        "-c"
        ''grim -g "$(slurp -w)" - | ${config.home.homeDirectory}/bin/swappy-fixed -f -''
      ];
    };

    "Ctrl+Print" = {
      allow-inhibiting = false;
      action.spawn = [
        "sh"
        "-c"
        ''grim - | ${config.home.homeDirectory}/bin/swappy-fixed -f -''
      ];
    };

    "Alt+Print" = {
      allow-inhibiting = false;
      action.spawn = [
        "sh"
        "-c"
        ''grim -g "$(slurp)" - | wl-copy''
      ];
    };

    "Mod+Print" = {
      allow-inhibiting = false;
      action.spawn = [
        "sh"
        "-c"
        ''grim -g "$(slurp)" ~/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png''
      ];
    };

    "Mod+Shift+C" = {
      action.spawn = [
        (lib.getExe pkgs.hyprpicker)
        "-a" # Automatically copy the color to the clipboard
      ];
    };
    "Mod+N" = {
      action.spawn = [
        "makoctl"
        "dismiss"
      ];
    };

    "Mod+Shift+N" = {
      action.spawn = [
        "makoctl"
        "dismiss"
        "--all"
      ];
    };

    "Mod+Ctrl+N" = {
      action.spawn = [
        "makoctl"
        "invoke"
      ];
    };

    # -----------------------------------------------------------------------------
    # -- Window & Column Management
    # -----------------------------------------------------------------------------
    "Mod+Q".action.close-window = {};
    "Mod+Shift+Q".action.close-window = {};
    "Mod+Alt+Q".action.spawn = [
      "sh"
      "-c"
      "PID=$(${pkgs.niri}/bin/niri msg focused-window | ${pkgs.jq}/bin/jq -r '.pid // empty'); [ -n \"$PID\" ] && kill -9 \"$PID\""
    ];

    "Mod+Shift+V".action.toggle-window-floating = {};

    "Mod+F".action.maximize-column = {};
    "Mod+Shift+F".action.fullscreen-window = {};
    "Mod+Ctrl+Shift+F".action.toggle-windowed-fullscreen = {};
    "Mod+Ctrl+F".action.expand-column-to-available-width = {};

    "Mod+R".action.switch-preset-column-width = {};
    "Mod+Shift+R".action.switch-preset-window-height = {};
    "Mod+Ctrl+R".action.reset-window-height = {};

    "Mod+Minus".action.set-column-width = "-10%";
    "Mod+Equal".action.set-column-width = "+10%";

    "Mod+Shift+Minus".action.set-window-height = "-10%";
    "Mod+Shift+Equal".action.set-window-height = "+10%";

    "Mod+C".action.center-column = {};
    "Mod+Ctrl+C".action.center-visible-columns = {};

    "Mod+BracketLeft".action.consume-or-expel-window-left = {};
    "Mod+BracketRight".action.consume-or-expel-window-right = {};
    "Mod+Comma".action.consume-window-into-column = {};
    "Mod+Period".action.expel-window-from-column = {};

    "Mod+W".action.toggle-column-tabbed-display = {};

    # Quick floating window toggle (tilde key)
    "Mod+Grave".action.toggle-window-floating = {};

    # -----------------------------------------------------------------------------
    # -- Focus & Movement (within a workspace)
    # -----------------------------------------------------------------------------
    "Mod+Left".action.focus-column-left = {};
    "Mod+Down".action.focus-window-down = {};
    "Mod+Up".action.focus-window-up = {};
    "Mod+Right".action.focus-column-right = {};
    "Mod+H".action.focus-column-left = {};
    "Mod+J".action.focus-window-down = {};
    "Mod+K".action.focus-window-up = {};
    "Mod+L".action.focus-column-right = {};
    "Mod+Home".action.focus-column-first = {};
    "Mod+End".action.focus-column-last = {};
    "Mod+Ctrl+Home".action.move-column-to-first = {};
    "Mod+Ctrl+End".action.move-column-to-last = {};

    # Alt+Tab window switching
    "Alt+Tab".action.focus-window-or-workspace-down = {};
    "Alt+Shift+Tab".action.focus-window-or-workspace-up = {};

    # -----------------------------------------------------------------------------
    # -- Workspace & Monitor Management
    # -----------------------------------------------------------------------------
    "Mod+O".action.toggle-overview = {};

    "Mod+Page_Down".action.focus-workspace-down = {};
    "Mod+Page_Up".action.focus-workspace-up = {};
    "Mod+U".action.focus-workspace-down = {};
    "Mod+I".action.focus-workspace-up = {};

    "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = {};
    "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = {};
    "Mod+Ctrl+U".action.move-column-to-workspace-down = {};
    "Mod+Ctrl+I".action.move-column-to-workspace-up = {};

    "Mod+Shift+Page_Down".action.move-workspace-down = {};
    "Mod+Shift+Page_Up".action.move-workspace-up = {};
    "Mod+Shift+U".action.move-workspace-down = {};
    "Mod+Shift+I".action.move-workspace-up = {};

    "Mod+1".action.focus-workspace = 1;
    "Mod+2".action.focus-workspace = 2;
    "Mod+3".action.focus-workspace = 3;
    "Mod+4".action.focus-workspace = 4;
    "Mod+5".action.focus-workspace = 5;
    "Mod+6".action.focus-workspace = 6;
    "Mod+7".action.focus-workspace = 7;
    "Mod+8".action.focus-workspace = 8;
    "Mod+9".action.focus-workspace = 9;
    "Mod+0".action.focus-workspace = 10;

    "Mod+Ctrl+1".action.move-column-to-workspace = 1;
    "Mod+Ctrl+2".action.move-column-to-workspace = 2;
    "Mod+Ctrl+3".action.move-column-to-workspace = 3;
    "Mod+Ctrl+4".action.move-column-to-workspace = 4;
    "Mod+Ctrl+5".action.move-column-to-workspace = 5;
    "Mod+Ctrl+6".action.move-column-to-workspace = 6;
    "Mod+Ctrl+7".action.move-column-to-workspace = 7;
    "Mod+Ctrl+8".action.move-column-to-workspace = 8;
    "Mod+Ctrl+9".action.move-column-to-workspace = 9;
    "Mod+Ctrl+0".action.move-column-to-workspace = 10;

    "Mod+Shift+Left".action.focus-monitor-left = {};
    "Mod+Shift+Down".action.focus-monitor-down = {};
    "Mod+Shift+Up".action.focus-monitor-up = {};
    "Mod+Shift+Right".action.focus-monitor-right = {};
    "Mod+Shift+H".action.focus-monitor-left = {};
    "Mod+Shift+J".action.focus-monitor-down = {};
    "Mod+Shift+K".action.focus-monitor-up = {};
    "Mod+Shift+L".action.focus-monitor-right = {};

    # Column movement
    "Mod+Ctrl+Left".action.move-column-left = {};
    "Mod+Ctrl+Right".action.move-column-right = {};

    "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = {};
    "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = {};
    "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = {};
    "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = {};
    "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = {};
    "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = {};
    "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = {};
    "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = {};

    # -----------------------------------------------------------------------------
    # -- Hardware & System Controls
    # -----------------------------------------------------------------------------
    "XF86AudioPlay" = {
      allow-when-locked = true;
      action.spawn = [
        "playerctl"
        "play-pause"
      ];
    };
    "XF86AudioNext" = {
      allow-when-locked = true;
      action.spawn = [
        "playerctl"
        "next"
      ];
    };
    "XF86AudioPrev" = {
      allow-when-locked = true;
      action.spawn = [
        "playerctl"
        "previous"
      ];
    };

    "XF86MonBrightnessUp" = {
      allow-when-locked = true;
      action.spawn = [
        brightness
        "up"
      ];
    };
    "XF86MonBrightnessDown" = {
      allow-when-locked = true;
      action.spawn = [
        brightness
        "down"
      ];
    };

    "XF86AudioRaiseVolume" = {
      allow-when-locked = true;
      action.spawn = [
        "wpctl"
        "set-volume"
        "@DEFAULT_AUDIO_SINK@"
        "0.1+"
        "--limit"
        "1"
      ];
    };
    "XF86AudioLowerVolume" = {
      allow-when-locked = true;
      action.spawn = [
        "wpctl"
        "set-volume"
        "@DEFAULT_AUDIO_SINK@"
        "0.1-"
      ];
    };
    "XF86AudioMute" = {
      allow-when-locked = true;
      action.spawn = [
        "wpctl"
        "set-mute"
        "@DEFAULT_AUDIO_SINK@"
        "toggle"
      ];
    };
    "XF86AudioMicMute" = {
      allow-when-locked = true;
      action.spawn = [
        "wpctl"
        "set-mute"
        "@DEFAULT_AUDIO_SOURCE@"
        "toggle"
      ];
    };

    "Mod+Alt+V".action.spawn = [(lib.getExe pkgs.pwvucontrol)];
    "Mod+Ctrl+V".action.spawn = [
      terminal
      "-e"
      "pulsemixer"
    ];

    # -----------------------------------------------------------------------------
    # -- Mouse & Wheel Bindings
    # -----------------------------------------------------------------------------
    "Mod+WheelScrollDown" = {
      cooldown-ms = 150;
      action.focus-workspace-down = {};
    };
    "Mod+WheelScrollUp" = {
      cooldown-ms = 150;
      action.focus-workspace-up = {};
    };
    "Mod+Ctrl+WheelScrollDown" = {
      cooldown-ms = 150;
      action.move-column-to-workspace-down = {};
    };
    "Mod+Ctrl+WheelScrollUp" = {
      cooldown-ms = 150;
      action.move-column-to-workspace-up = {};
    };

    "Mod+WheelScrollRight".action.focus-column-right = {};
    "Mod+WheelScrollLeft".action.focus-column-left = {};
    "Mod+Ctrl+WheelScrollRight".action.move-column-right = {};
    "Mod+Ctrl+WheelScrollLeft".action.move-column-left = {};

    "Mod+Shift+WheelScrollDown".action.focus-column-right = {};
    "Mod+Shift+WheelScrollUp".action.focus-column-left = {};
    "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = {};
    "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = {};
  };
}
