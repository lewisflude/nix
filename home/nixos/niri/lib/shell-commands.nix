# Shell command builders for niri keybinds
# Extracts common shell patterns to reduce duplication
{ pkgs, lib }:
let
  # Helper to build shell commands with proper escaping
  buildShellCmd = script: [
    "sh"
    "-c"
    script
  ];

  # Screenshot filename generator
  screenshotFilename = prefix: "$HOME/Pictures/Screenshots/${prefix}-$(date +%Y%m%d-%H%M%S).png";

  # Common screenshot operations
  saveAndCopy = file: ''
    grim -t png "${file}" && \
    wl-copy < "${file}" && \
    notify-send "Screenshot" "Saved and copied to clipboard" -i "${file}"
  '';

  saveAreaWithSatty = file: ''
    GEOM=$(slurp) && if [ -n "$GEOM" ]; then
      grim -g "$GEOM" -t ppm - | satty --filename - --fullscreen --output-filename "${file}"
      notify-send "Screenshot" "Area saved" -i "${file}"
    fi
  '';

  saveFullScreenWithSatty = file: ''
    grim -t ppm - | satty --filename - --fullscreen --output-filename "${file}"
    notify-send "Screenshot" "Screen saved" -i "${file}"
  '';
in
{
  # Screenshot commands
  screenshot = {
    # Full screen to file and clipboard
    fullScreenCopy = buildShellCmd ''
      FILE="${screenshotFilename "screenshot"}"
      ${saveAndCopy "$FILE"}
    '';

    # Area with satty annotation
    areaSatty = buildShellCmd ''
      FILE="${screenshotFilename "satty"}"
      ${saveAreaWithSatty "$FILE"}
    '';

    # Full screen with satty annotation
    fullScreenSatty = buildShellCmd ''
      FILE="${screenshotFilename "satty"}"
      ${saveFullScreenWithSatty "$FILE"}
    '';

    # Area to clipboard only
    areaClipboard = buildShellCmd ''
      GEOM=$(slurp) && if [ -n "$GEOM" ]; then
        grim -g "$GEOM" -t png | wl-copy && \
        notify-send "Screenshot" "Area copied to clipboard"
      fi
    '';

    # Area saved and copied to clipboard
    areaSaveAndCopy = buildShellCmd ''
      GEOM=$(slurp) && if [ -n "$GEOM" ]; then
        FILE="${screenshotFilename "screenshot"}"
        grim -g "$GEOM" -t png "$FILE" && \
        wl-copy < "$FILE" && \
        notify-send "Screenshot" "Area saved and copied to clipboard" -i "$FILE"
      fi
    '';

    # Region capture (Windows/macOS style)
    regionCapture = buildShellCmd ''
      FILE="${screenshotFilename "region"}"
      grim -g "$(slurp)" - | tee "$FILE" | wl-copy && \
      notify-send "Region Captured" "Saved to $FILE and Clipboard" -i "$FILE"
    '';
  };

  # Window management
  window = {
    # Force kill focused window
    forceKill = buildShellCmd ''
      PID=$(${pkgs.niri}/bin/niri msg focused-window | ${pkgs.jq}/bin/jq -r '.pid // empty')
      [ -n "$PID" ] && kill -9 "$PID"
    '';
  };

  # System commands
  system = {
    # Power menu with fuzzel
    powerMenu = buildShellCmd ''
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

    # Toggle displays (off then on with 2s delay)
    toggleDisplays = buildShellCmd ''
      niri msg action power-off-monitors && \
      sleep 2 && \
      niri msg action power-on-monitors
    '';
  };

  # Monitor management
  monitor = {
    # Show output info
    showOutputInfo = buildShellCmd ''
      OUTPUTS=$(niri msg outputs --json | ${pkgs.jq}/bin/jq -r '.[] | "\(.name): \(.mode.width)x\(.mode.height) @ \(.mode.refresh)Hz (scale: \(.scale))"')
      notify-send "Outputs" "$OUTPUTS" -t 5000
    '';
  };
}
