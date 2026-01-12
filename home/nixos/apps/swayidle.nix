{
  pkgs,
  themeContext ? null,
  themeLib,
  ...
}:
let
  # Generate fallback theme using shared themeLib
  fallbackTheme = themeLib.generateTheme "dark" { };

  # Use Signal theme if available, otherwise use fallback
  signalTheme =
    if themeContext != null && themeContext ? theme && themeContext.theme != null then
      themeContext.theme
    else
      fallbackTheme;
  inherit (signalTheme) colors;

  withAlpha = color: alpha: "${color}${alpha}";

  lockCommand = pkgs.writeShellScript "signal-lock-screen" ''
    exec ${pkgs.swaylock-effects}/bin/swaylock -f
  '';

  powerOffMonitors = "${pkgs.niri}/bin/niri msg action power-off-monitors";
  powerOnMonitors = "${pkgs.niri}/bin/niri msg action power-on-monitors";

  # Helper scripts for streaming - disable auto-lock temporarily
  streamingHelper = pkgs.writeShellScriptBin "streaming-mode" ''
    OVERRIDE_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/swayidle.service.d"
    OVERRIDE_FILE="$OVERRIDE_DIR/streaming-override.conf"

    case "$1" in
      on)
        echo "Disabling auto-lock for streaming..."

        # Create override to disable restart
        mkdir -p "$OVERRIDE_DIR"
        cat > "$OVERRIDE_FILE" <<EOF
    [Service]
    Restart=no
    EOF

        # Reload and stop service
        systemctl --user daemon-reload
        systemctl --user stop swayidle.service

        # Unlock if currently locked
        pkill swaylock 2>/dev/null || true
        echo "Streaming mode enabled. Auto-lock disabled."
        ;;
      off)
        echo "Re-enabling auto-lock..."

        # Remove override
        rm -f "$OVERRIDE_FILE"
        rmdir "$OVERRIDE_DIR" 2>/dev/null || true

        # Reload and start service
        systemctl --user daemon-reload
        systemctl --user start swayidle.service
        echo "Streaming mode disabled. Auto-lock re-enabled."
        ;;
      *)
        echo "Usage: streaming-mode {on|off}"
        echo "  on  - Disable auto-lock for streaming"
        echo "  off - Re-enable auto-lock"
        exit 1
        ;;
    esac
  '';
in
{
  home.packages = [ streamingHelper ];
  services.swayidle = {
    # Disabled - no auto-lock or idle timeouts
    enable = false;
    package = pkgs.swayidle;
    systemdTarget = "graphical-session.target";
    timeouts = [
      {
        timeout = 300;
        command = "${lockCommand}";
      }
      {
        timeout = 600;
        command = powerOffMonitors;
        resumeCommand = powerOnMonitors;
      }
    ];
    events = {
      before-sleep = "${lockCommand}";
      lock = "${lockCommand}";
      after-resume = powerOnMonitors;
    };
  };

  # Configure swaylock-effects with Signal theme (OKLCH perceptual color system)
  # Signal: Perception, engineered - scientifically designed for clarity and accessibility
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      # === Signal Theme Colors ===
      # Ring colors (state feedback with semantic meaning)
      ring-color = colors."accent-focus".hexRaw; # Blue - Default/focus state
      ring-ver-color = colors."accent-primary".hexRaw; # Green - Verifying (success)
      ring-clear-color = colors."accent-info".hexRaw; # Cyan - Clearing input
      ring-wrong-color = colors."accent-danger".hexRaw; # Red - Wrong password

      # Line colors (separator between ring and inside)
      line-color = "00000000"; # Transparent - clean aesthetic
      line-ver-color = colors."accent-primary".hexRaw; # Green when verifying
      line-clear-color = colors."accent-info".hexRaw; # Cyan when clearing
      line-wrong-color = colors."accent-danger".hexRaw; # Red when wrong

      # Inside colors (indicator background with alpha for depth)
      inside-color = withAlpha colors."surface-base".hexRaw "dd"; # Base with transparency
      inside-ver-color = withAlpha colors."surface-subtle".hexRaw "dd"; # Subtle variation when verifying
      inside-clear-color = withAlpha colors."surface-base".hexRaw "bb"; # More transparent when clearing
      inside-wrong-color = withAlpha colors."surface-emphasis".hexRaw "dd"; # Emphasized on error

      # Separator (not visible, kept for completeness)
      separator-color = "00000000"; # Transparent

      # Text colors (high contrast for readability)
      text-color = colors."text-primary".hexRaw; # Primary text (time/date)
      text-ver-color = colors."accent-primary".hexRaw; # Green when verifying
      text-clear-color = colors."accent-info".hexRaw; # Cyan when clearing
      text-wrong-color = colors."accent-danger".hexRaw; # Red on wrong password

      # Highlight colors (keyboard feedback)
      key-hl-color = colors."accent-info".hexRaw; # Cyan for key highlight
      bs-hl-color = colors."accent-danger".hexRaw; # Red for backspace

      # Layout/Background colors
      color = colors."surface-base".hexRaw; # Fallback background color

      # === Visual Effects (swaylock-effects exclusive) ===
      screenshots = true; # Use actual screenshot as background
      effect-blur = "7x5"; # Gaussian blur for privacy and aesthetics
      effect-vignette = "0.5:0.5"; # Subtle vignette for depth and focus
      fade-in = 0.2; # Smooth 200ms fade-in transition
      grace = 2; # 2 second grace period before requiring password

      # === Indicator Configuration ===
      clock = true; # Show time and date
      indicator = true; # Always show indicator
      indicator-idle-visible = false; # Hide when idle (grace period)
      indicator-radius = 110; # Size of circular indicator
      indicator-thickness = 7; # Ring thickness
      font-size = 24; # Readable clock text

      # === Text Customization ===
      datestr = "%A, %B %e"; # e.g., "Tuesday, December 9"
      timestr = "%I:%M %p"; # 12-hour format with AM/PM
      show-failed-attempts = true; # Security feedback

      # === Accessibility ===
      ignore-empty-password = false; # Don't submit empty passwords
      show-keyboard-layout = true; # Show keyboard layout (helpful for multiple layouts)
    };
  };
}
