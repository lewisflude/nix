{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  # Get Catppuccin palette colors for MPV
  catppuccinPalette =
    if lib.hasAttrByPath ["catppuccin" "sources" "palette"] config
    then (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
      .${config.catppuccin.flavor}.colors
    else let
      catppuccinSrc =
        inputs.catppuccin.src or inputs.catppuccin.outPath or (throw "Cannot find catppuccin source");
    in
      (pkgs.lib.importJSON (catppuccinSrc + "/palette.json")).mocha.colors;
in {
  # MPV configuration with Catppuccin colors
  # Note: MPV OSD colors use RGB in hex format
  xdg.configFile."mpv/config".text = ''
    # Catppuccin Mocha theme for MPV
    # Video settings
    vo=wayland
    gpu-context=wayland
    hwdec=auto-safe

    # OSD colors (Catppuccin Mocha)
    osd-color=${catppuccinPalette.text.hex}
    osd-border-color=${catppuccinPalette.base.hex}
    osd-shadow-color=${catppuccinPalette.crust.hex}
    osd-back-color=${catppuccinPalette.base.hex}cc

    # Subtitle colors
    sub-color=${catppuccinPalette.text.hex}
    sub-border-color=${catppuccinPalette.base.hex}
    sub-shadow-color=${catppuccinPalette.crust.hex}
    sub-back-color=${catppuccinPalette.base.hex}cc

    # Seek bar colors
    osd-bar-align-y=0.9
    osd-bar-w=100
    osd-bar-h=2
    osd-bar-border-size=1
    osd-bar-pos-y=0.9
    osd-bar-color=${catppuccinPalette.mauve.hex}
    osd-bar-border-color=${catppuccinPalette.lavender.hex}

    # UI settings
    osd-font-size=24
    osd-duration=2000
    osd-margin-x=40
    osd-margin-y=40

    # Playback settings
    cache=yes
    cache-secs=60
    demuxer-max-bytes=500M
    demuxer-max-back-bytes=500M
  '';
}
