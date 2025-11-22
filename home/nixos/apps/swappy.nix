{
  config,
  pkgs,
  lib,
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
  programs.swappy = {
    enable = true;
    settings = {
      Default = {
        save_dir = "${config.home.homeDirectory}/Pictures/Screenshots";
        save_filename_format = "swappy-%Y%m%d-%H%M%S.png";
        show_panel = true;
        fill_color = "${colors."surface-base".hex}80";
        line_color = "${colors."accent-focus".hex}ff";
        text_color = "${colors."text-primary".hex}ff";
        text_font = "sans-serif";
        text_size = 16;
        line_size = 5;
        paint_mode = "brush";
        early_exit = false;
        fill_shape = false;
        auto_save = false;
      };
    };
  };
  home.file."Pictures/Screenshots/.keep".text = "";
  home.packages = [
    (pkgs.writeShellApplication {
      name = "swappy-fixed";
      runtimeInputs = [
        pkgs.swappy
        pkgs.gnugrep
      ];
      text = ''
        export GDK_SCALE=1
        export GDK_DPI_SCALE=1
        # GTK theme is set by theming system (home/common/theming/applications/gtk.nix)
        exec ${pkgs.swappy}/bin/swappy "$@" 2> >(grep -v "Theme parsing error: gtk.css" >&2)
      '';
    })
  ];
}
