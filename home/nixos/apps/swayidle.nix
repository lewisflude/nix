{
  pkgs,
  inputs,
  system,
  ...
}: let
  # Use FULL Catppuccin palette - access all semantic colors
  catppuccinPalette =
    pkgs.lib.importJSON
    (
      inputs.catppuccin.packages.${system}.catppuccin-gtk-theme.src + "/palette.json"
    ).mocha.colors;

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
