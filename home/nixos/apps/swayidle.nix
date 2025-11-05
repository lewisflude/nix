{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  # Use FULL Catppuccin palette - access all semantic colors
  # Uses catppuccin.nix module palette when available, falls back to direct input access
  catppuccinPalette =
    if lib.hasAttrByPath ["catppuccin" "sources" "palette"] config
    then
      # Use catppuccin.nix module palette if available
      (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
      .${config.catppuccin.flavor}.colors
    else if inputs ? catppuccin
    then
      # Try to get palette directly from catppuccin input
      # catppuccin/nix repository has palette.json at the root
      let
        catppuccinSrc = inputs.catppuccin.src or inputs.catppuccin.outPath or null;
      in
        if catppuccinSrc != null
        then (pkgs.lib.importJSON (catppuccinSrc + "/palette.json")).mocha.colors
        else throw "Cannot find catppuccin source (input exists but src/outPath not found)"
    else throw "Cannot find catppuccin: input not available and config.catppuccin.sources.palette not set";

  # Use Catppuccin colors directly for accurate theming
  palette = catppuccinPalette;
in {
  services.swayidle = {
    enable = true;
    package = pkgs.swayidle;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.swaylock-effects}/bin/swaylock --screenshots --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5 --ring-color ${palette.mauve.hex} --key-hl-color ${palette.lavender.hex} --line-color 00000000 --inside-color ${palette.base.hex}88 --separator-color 00000000 --text-color ${palette.text.hex} --grace 2 --fade-in 0.2";
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
