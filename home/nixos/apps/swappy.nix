{
  config,
  pkgs,
  ...
}: {
  programs.swappy = {
    enable = true;
    settings = {
      Default = {
        save_dir = "${config.home.homeDirectory}/Pictures/Screenshots";
        save_filename_format = "swappy-%Y%m%d-%H%M%S.png";
        show_panel = true;
        fill_color = "#00000080";
        line_color = "#ffffffff";
        text_color = "#ffffffff";
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
  home.file = {
    "Pictures/Screenshots/.keep".text = "";
    "bin/swappy-fixed" = {
      text = ''
        export GDK_SCALE=1
        export GDK_DPI_SCALE=1
        export GTK_THEME=Catppuccin-GTK-Dark
        exec ${pkgs.swappy}/bin/swappy "$@" 2> >(grep -v "Theme parsing error: gtk.css" >&2)
      '';
      executable = true;
    };
  };
}
