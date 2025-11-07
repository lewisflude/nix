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
    "text-primary" = { hex = "#c0c3d1"; };
    "surface-base" = { hex = "#1e1f26"; };
    "surface-emphasis" = { hex = "#2d2e39"; };
    "accent-focus" = { hex = "#5a7dcf"; };
    "accent-info" = { hex = "#5aabb9"; };
  };
in
{

  xdg.configFile."mpv/config".text = ''


    vo=wayland
    gpu-context=wayland
    hwdec=auto-safe


    osd-color=${colors."text-primary".hex}
    osd-border-color=${colors."surface-base".hex}
    osd-shadow-color=${colors."surface-emphasis".hex}
    osd-back-color=${colors."surface-base".hex}cc


    sub-color=${colors."text-primary".hex}
    sub-border-color=${colors."surface-base".hex}
    sub-shadow-color=${colors."surface-emphasis".hex}
    sub-back-color=${colors."surface-base".hex}cc


    osd-bar-align-y=0.9
    osd-bar-w=100
    osd-bar-h=2
    osd-bar-border-size=1
    osd-bar-pos-y=0.9
    osd-bar-color=${colors."accent-focus".hex}
    osd-bar-border-color=${colors."accent-info".hex}


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
