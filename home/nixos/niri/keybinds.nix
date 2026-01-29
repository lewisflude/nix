# Niri Keybindings - Consolidated (75 essential keybinds)
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) getExe;
  screenLocker = getExe pkgs.swaylock-effects;
  terminal = getExe pkgs.ghostty;

  # Helper functions
  uwsmApp = app: [ (getExe pkgs.uwsm) "app" "--" app ];
  termWith = cmd: [ terminal "-e" cmd ];
  termWithArgs = args: [ terminal "-e" ] ++ args;
  launcher = uwsmApp (getExe pkgs.fuzzel);

  # Shell command builder
  buildShellCmd = script: [
    "sh"
    "-c"
    script
  ];

  # Screenshot filename generator
  screenshotFilename = prefix: "$HOME/Pictures/Screenshots/${prefix}-$(date +%Y%m%d-%H%M%S).png";
in
{
  binds = {
    # ============================================================================
    # WINDOW MANAGEMENT (14 binds)
    # ============================================================================

    "Mod+Q".action.close-window = {};
    "Mod+Shift+Q".action.spawn = buildShellCmd ''
      PID=$(${pkgs.niri}/bin/niri msg focused-window | ${pkgs.jq}/bin/jq -r '.pid // empty')
      [ -n "$PID" ] && kill -9 "$PID"
    '';
    "Mod+Grave".action.toggle-window-floating = {};
    "Mod+F".action.maximize-column = {};
    "Mod+Shift+F".action.fullscreen-window = {};

    # Window focus - arrows + vim keys
    "Mod+Down".action.focus-window-down = {};
    "Mod+Up".action.focus-window-up = {};
    "Mod+J".action.focus-window-down = {};
    "Mod+K".action.focus-window-up = {};

    # ============================================================================
    # COLUMN NAVIGATION (14 binds)
    # ============================================================================

    # Focus column - arrows + vim keys
    "Mod+Left".action.focus-column-left = {};
    "Mod+Right".action.focus-column-right = {};
    "Mod+H".action.focus-column-left = {};
    "Mod+L".action.focus-column-right = {};

    # Move column - arrows + vim keys
    "Mod+Ctrl+Left".action.move-column-left = {};
    "Mod+Ctrl+Right".action.move-column-right = {};
    "Mod+Ctrl+H".action.move-column-left = {};
    "Mod+Ctrl+L".action.move-column-right = {};

    # Jump to edges
    "Mod+Home".action.focus-column-first = {};
    "Mod+End".action.focus-column-last = {};
    "Mod+Ctrl+Home".action.move-column-to-first = {};
    "Mod+Ctrl+End".action.move-column-to-last = {};

    # ============================================================================
    # COLUMN LAYOUT (8 binds)
    # ============================================================================

    "Mod+R".action.switch-preset-column-width = {};
    "Mod+Minus".action.set-column-width = "-10%";
    "Mod+Equal".action.set-column-width = "+10%";
    "Mod+C".action.center-column = {};
    "Mod+Comma".action.consume-window-into-column = {};
    "Mod+Period".action.expel-window-from-column = {};
    "Mod+W".action.toggle-column-tabbed-display = {};

    # ============================================================================
    # WORKSPACE NAVIGATION (10 binds)
    # ============================================================================

    # Focus workspace
    "Mod+Page_Down".action.focus-workspace-down = {};
    "Mod+Page_Up".action.focus-workspace-up = {};
    "Mod+U".action.focus-workspace-up = {};
    "Mod+I".action.focus-workspace-down = {};

    # Move to workspace
    "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = {};
    "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = {};
    "Mod+Ctrl+U".action.move-column-to-workspace-up = {};
    "Mod+Ctrl+I".action.move-column-to-workspace-down = {};

    # Alt-Tab navigation
    "Alt+Tab".action.focus-window-or-workspace-down = {};
    "Alt+Shift+Tab".action.focus-window-or-workspace-up = {};

    # Overview
    "Mod+O".action.toggle-overview = {};

    # ============================================================================
    # MONITOR MANAGEMENT (6 binds)
    # ============================================================================

    # Focus monitor - vim directional
    "Mod+Shift+H".action.focus-monitor-left = {};
    "Mod+Shift+J".action.focus-monitor-down = {};
    "Mod+Shift+K".action.focus-monitor-up = {};
    "Mod+Shift+L".action.focus-monitor-right = {};

    # Focus monitor - arrows
    "Mod+Shift+Left".action.focus-monitor-left = {};
    "Mod+Shift+Right".action.focus-monitor-right = {};

    # ============================================================================
    # APPLICATIONS (5 binds)
    # ============================================================================

    "Mod+T".action.spawn = [ terminal ];
    "F13".action.spawn = [ terminal ];
    "Mod+D".action.spawn = launcher;
    "Mod+B".action.spawn = uwsmApp (getExe pkgs.google-chrome);
    "Mod+E".action.spawn = termWith "yazi";
    "Mod+Shift+O".action.spawn = termWithArgs [ (getExe pkgs.helix) "${config.home.homeDirectory}/.config/nix" ];

    # ============================================================================
    # SYSTEM CONTROLS (9 binds)
    # ============================================================================

    "Super+Alt+L".action.spawn = [ screenLocker "-f" ];
    "Mod+Shift+E".action.quit = {};
    "Mod+X".action.spawn = buildShellCmd ''
      OPTIONS="Logout\nSuspend\nHibernate\nReboot\nShutdown"
      CHOICE=$(echo -e "$OPTIONS" | fuzzel --dmenu --prompt 'Power:')
      case "$CHOICE" in
        Logout) niri msg action quit ;;
        Suspend) systemctl suspend ;;
        Hibernate) systemctl hibernate ;;
        Reboot) systemctl reboot ;;
        Shutdown) systemctl poweroff ;;
      esac
    '';
    "Mod+N".action.spawn = [ "makoctl" "dismiss" ];
    "Mod+Shift+N".action.spawn = [ "makoctl" "dismiss" "--all" ];
    "Mod+Escape" = { allow-inhibiting = false; action.toggle-keyboard-shortcuts-inhibit = {}; };
    "Mod+Ctrl+Shift+R".action.spawn = [ "niri" "msg" "action" "reload-config" ];
    "Mod+Shift+Slash".action.show-hotkey-overlay = {};
    "Mod+V".action.spawn = buildShellCmd "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy";

    # ============================================================================
    # MEDIA CONTROLS (5 binds)
    # ============================================================================

    "XF86AudioPlay" = { allow-when-locked = true; action.spawn = [ "playerctl" "play-pause" ]; };
    "XF86AudioNext" = { allow-when-locked = true; action.spawn = [ "playerctl" "next" ]; };
    "XF86AudioPrev" = { allow-when-locked = true; action.spawn = [ "playerctl" "previous" ]; };
    "XF86AudioRaiseVolume" = { allow-when-locked = true; action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+" "--limit" "1" ]; };
    "XF86AudioLowerVolume" = { allow-when-locked = true; action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-" ]; };

    # ============================================================================
    # SCREENSHOTS (4 binds)
    # ============================================================================

    "Print" = {
      allow-inhibiting = false;
      action.spawn = buildShellCmd ''
        FILE="${screenshotFilename "screenshot"}"
        grim -t png "$FILE" && \
        wl-copy < "$FILE" && \
        notify-send "Screenshot" "Saved and copied to clipboard" -i "$FILE"
      '';
    };

    "Shift+Print" = {
      allow-inhibiting = false;
      action.spawn = buildShellCmd ''
        FILE="${screenshotFilename "satty"}"
        GEOM=$(slurp) && if [ -n "$GEOM" ]; then
          grim -g "$GEOM" -t ppm - | satty --filename - --fullscreen --output-filename "$FILE"
          notify-send "Screenshot" "Area saved" -i "$FILE"
        fi
      '';
    };

    "Alt+Print" = {
      allow-inhibiting = false;
      action.spawn = buildShellCmd ''
        GEOM=$(slurp) && if [ -n "$GEOM" ]; then
          grim -g "$GEOM" -t png | wl-copy && \
          notify-send "Screenshot" "Area copied to clipboard"
        fi
      '';
    };

    "Mod+Shift+S" = {
      allow-inhibiting = false;
      action.spawn = buildShellCmd ''
        FILE="${screenshotFilename "region"}"
        grim -g "$(slurp)" - | tee "$FILE" | wl-copy && \
        notify-send "Region Captured" "Saved to $FILE and Clipboard" -i "$FILE"
      '';
    };

    # ============================================================================
    # MOUSE (4 binds)
    # ============================================================================

    "Mod+WheelScrollDown" = { cooldown-ms = 150; action.focus-column-right = {}; };
    "Mod+WheelScrollUp" = { cooldown-ms = 150; action.focus-column-left = {}; };
    "Mod+Shift+WheelScrollDown" = { cooldown-ms = 150; action.focus-workspace-down = {}; };
    "Mod+Shift+WheelScrollUp" = { cooldown-ms = 150; action.focus-workspace-up = {}; };
  };
}
