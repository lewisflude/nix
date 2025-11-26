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
  inherit (themeContext.theme or fallbackTheme) colors;
in
{
  services.swayidle = {
    enable = true;
    package = pkgs.swayidle;
    timeouts = [
      {
        timeout = 300;
        # Colors are configured via programs.swaylock.settings (see below)
        # Only pass non-color arguments here
        # -f flag is required for proper ext-session-lock integration with niri
        command = "${pkgs.swaylock-effects}/bin/swaylock -f --screenshots --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5 --grace 2 --fade-in 0.2";
      }
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
    ];
    events = [
      {
        event = "before-sleep";
        # -f flag is required for proper ext-session-lock integration with niri
        command = "${pkgs.swaylock-effects}/bin/swaylock -f";
      }
    ];
  };

  # Configure swaylock colors via Home Manager settings (best practice)
  # This is the correct way to theme swaylock - not via command-line args
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      # Signal theme colors (swaylock expects hex without # prefix)
      ring-color = colors."accent-focus".hexRaw;
      key-hl-color = colors."accent-info".hexRaw;
      line-color = "00000000"; # Transparent
      inside-color = "${colors."surface-base".hexRaw}88"; # With alpha (~53% opacity)
      separator-color = "00000000"; # Transparent
      text-color = colors."text-primary".hexRaw;

      # Visual settings
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      indicator-thickness = 7;
      show-failed-attempts = true;
    };
  };
}
