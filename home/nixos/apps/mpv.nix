{
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
