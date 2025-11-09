{
  pkgs,
  lib,
  signalPalette ? null,
  ...
}:
let
  # Import shared palette (single source of truth) for fallback
  themeHelpers = import ../../../modules/shared/features/theming/helpers.nix { inherit lib; };
  themeImport = themeHelpers.importTheme {
    repoRootPath = ../../..;
  };
  fallbackTheme = themeImport.generateTheme "dark";

  # Use Signal theme if available, otherwise use fallback from shared palette
  theme = if signalPalette != null then signalPalette else fallbackTheme;
  colors = theme.semantic;
in
{
  services.swayidle = {
    enable = true;
    package = pkgs.swayidle;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.swaylock-effects}/bin/swaylock --screenshots --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5 --ring-color ${colors."accent-focus".hex} --key-hl-color ${colors."accent-info".hex} --line-color 00000000 --inside-color ${colors."surface-base".hex}88 --separator-color 00000000 --text-color ${colors."text-primary".hex} --grace 2 --fade-in 0.2";
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
        command = "${pkgs.swaylock-effects}/bin/swaylock";
      }
    ];
  };
}
