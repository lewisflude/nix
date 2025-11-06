{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let

  catppuccinPalette =
    if lib.hasAttrByPath [ "catppuccin" "sources" "palette" ] config then
      (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
      .${config.catppuccin.flavor}.colors
    else if inputs ? catppuccin then
      let
        catppuccinSrc = inputs.catppuccin.src or inputs.catppuccin.outPath or null;
      in
      if catppuccinSrc != null then
        (pkgs.lib.importJSON (catppuccinSrc + "/palette.json")).mocha.colors
      else
        throw "Cannot find catppuccin source (input exists but src/outPath not found)"
    else
      throw "Cannot find catppuccin: input not available and config.catppuccin.sources.palette not set";
in
{

  xdg.configFile."mpv/config".text = ''


    vo=wayland
    gpu-context=wayland
    hwdec=auto-safe


    osd-color=${catppuccinPalette.text.hex}
    osd-border-color=${catppuccinPalette.base.hex}
    osd-shadow-color=${catppuccinPalette.crust.hex}
    osd-back-color=${catppuccinPalette.base.hex}cc


    sub-color=${catppuccinPalette.text.hex}
    sub-border-color=${catppuccinPalette.base.hex}
    sub-shadow-color=${catppuccinPalette.crust.hex}
    sub-back-color=${catppuccinPalette.base.hex}cc


    osd-bar-align-y=0.9
    osd-bar-w=100
    osd-bar-h=2
    osd-bar-border-size=1
    osd-bar-pos-y=0.9
    osd-bar-color=${catppuccinPalette.mauve.hex}
    osd-bar-border-color=${catppuccinPalette.lavender.hex}


    osd-font-size=24
    osd-duration=2000
    osd-margin-x=40
    osd-margin-y=40


    cache=yes
    cache-secs=60
    demuxer-max-bytes=500M
    demuxer-max-back-bytes=500M
  '';
}
