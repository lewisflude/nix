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
in
{
  services.swayidle = {
    enable = true;
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

  # Configure swaylock colors via Home Manager settings (best practice)
  # This is the correct way to theme swaylock - not via command-line args
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      # Signal theme colors (swaylock expects hex without # prefix)
      ring-color = colors."accent-focus".hexRaw;
      ring-ver-color = colors."accent-primary".hexRaw;
      ring-clear-color = colors."accent-info".hexRaw;
      ring-wrong-color = colors."accent-danger".hexRaw;
      line-color = "00000000"; # Transparent
      line-ver-color = colors."accent-primary".hexRaw;
      line-clear-color = colors."accent-info".hexRaw;
      line-wrong-color = colors."accent-danger".hexRaw;
      inside-color = withAlpha colors."surface-base".hexRaw "dd";
      inside-ver-color = withAlpha colors."surface-subtle".hexRaw "dd";
      inside-clear-color = withAlpha colors."surface-base".hexRaw "bb";
      inside-wrong-color = withAlpha colors."surface-emphasis".hexRaw "dd";
      separator-color = "00000000"; # Transparent
      text-color = colors."text-primary".hexRaw;
      text-ver-color = colors."accent-primary".hexRaw;
      text-clear-color = colors."accent-info".hexRaw;
      text-wrong-color = colors."accent-danger".hexRaw;
      key-hl-color = colors."accent-info".hexRaw;
      bs-hl-color = colors."accent-danger".hexRaw;

      # Visual settings
      clock = true;
      indicator = true;
      indicator-idle-visible = false;
      indicator-radius = 110;
      indicator-thickness = 7;
      font-size = 24;
      screenshots = true;
      effect-blur = "7x5";
      effect-vignette = "0.5:0.5";
      grace = 2;
      fade-in = 0.2;
      show-failed-attempts = true;
    };
  };
}
