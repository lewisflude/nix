{
  config,
  pkgs,
  ...
}: {
  xdg.configFile."swappy/config".text = ''
    [Default]
    save_dir=${config.home.homeDirectory}/Pictures/Screenshots
    save_filename_format=screenshot_%Y%m%d_%H%M%S.png
    show_panel=true
    line_size=5
    text_size=20
    text_font=sans-serif
    paint_mode=brush
    early_exit=true
    fill_shape=false
    auto_save=false
  '';

  home.file = {
    # Ensure Screenshots directory exists
    "Pictures/Screenshots/.keep".text = "";

    # Create a wrapper script to fix GTK/scaling issues
    "bin/swappy-fixed" = {
      text = ''
        #!/usr/bin/env bash
        export GDK_SCALE=1
        export GDK_DPI_SCALE=1
        export GTK_THEME=Catppuccin-GTK-Dark
        # Filter out specific GTK theme parsing warnings while preserving other messages
        exec ${pkgs.swappy}/bin/swappy "$@" 2> >(grep -v "Theme parsing error: gtk.css" >&2)
      '';
      executable = true;
    };
  };
}
