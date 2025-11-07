{
  pkgs,
  config,
  lib,
  scientificPalette ? null,
  ...
}:
let
  # Use scientific theme if available, fallback to neutral colors
  colors = if scientificPalette != null then scientificPalette.semantic else {
    "accent-focus" = { hex = "#5a7dcf"; };
    "accent-info" = { hex = "#5aabb9"; };
    "surface-base" = { hex = "#1e1f26"; };
    "text-primary" = { hex = "#c0c3d1"; };
  };
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
