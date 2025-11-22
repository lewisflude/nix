{
  themeContext ? null,
  themeLib,
  ...
}:
let
  # Generate fallback theme using shared themeLib
  fallbackTheme = themeLib.generateTheme "dark" { };

  # Use Signal theme if available, otherwise use fallback
  theme = themeContext.theme or fallbackTheme;
  inherit (theme) colors;
in
{
  programs.mpv = {
    enable = true;

    # Use config for regular settings (converted to attribute set)
    config = {
      # Wayland output
      vo = "wayland";
      gpu-context = "wayland";
      hwdec = "auto-safe";

      # OSD colors
      osd-color = colors."text-primary".hex;
      osd-border-color = colors."surface-base".hex;
      osd-shadow-color = colors."surface-emphasis".hex;
      osd-back-color = "${colors."surface-base".hex}cc";

      # Subtitle colors
      sub-color = colors."text-primary".hex;
      sub-border-color = colors."surface-base".hex;
      sub-shadow-color = colors."surface-emphasis".hex;
      sub-back-color = "${colors."surface-base".hex}cc";

      # OSD bar styling
      osd-bar-align-y = "0.9";
      osd-bar-w = 100;
      osd-bar-h = 2;
      osd-bar-border-size = 1;
      osd-bar-pos-y = "0.9";
      osd-bar-color = colors."accent-focus".hex;
      osd-bar-border-color = colors."accent-info".hex;

      # OSD text styling
      osd-font-size = 24;
      osd-duration = 2000;
      osd-margin-x = 40;
      osd-margin-y = 40;

      # Cache settings
      cache = "yes";
      cache-secs = 60;
      demuxer-max-bytes = "500M";
      demuxer-max-back-bytes = "500M";
    };

    # Use extraConfig for script-opts-append (special MPV directive)
    extraConfig = ''
      # Stats overlay theming
      script-opts-append=stats-border_color=${theme.formats.bgrHexRaw colors."divider-primary"}
      script-opts-append=stats-font_color=${theme.formats.bgrHexRaw colors."text-primary"}
      script-opts-append=stats-plot_bg_border_color=${theme.formats.bgrHexRaw colors."accent-info"}
      script-opts-append=stats-plot_bg_color=${theme.formats.bgrHexRaw colors."surface-base"}
      script-opts-append=stats-plot_color=${theme.formats.bgrHexRaw colors."accent-focus"}

      # uosc script theming
      script-opts-append=uosc-color=foreground=${colors."accent-focus".hexRaw},foreground_text=${colors."surface-base".hexRaw},background=${colors."surface-base".hexRaw},background_text=${colors."text-primary".hexRaw},curtain=${
        colors."surface-emphasis".hexRaw
      },success=${colors."accent-primary".hexRaw},error=${colors."accent-danger".hexRaw}
    '';
  };
}
