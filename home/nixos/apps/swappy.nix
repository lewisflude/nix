{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  # Get Catppuccin palette colors
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
  programs.swappy = {
    enable = true;
    settings = {
      Default = {
        save_dir = "${config.home.homeDirectory}/Pictures/Screenshots";
        save_filename_format = "swappy-%Y%m%d-%H%M%S.png";
        show_panel = true;
        fill_color = "${catppuccinPalette.base.hex}80"; # Base color with transparency
        line_color = "${catppuccinPalette.mauve.hex}ff"; # Mauve accent color
        text_color = "${catppuccinPalette.text.hex}ff"; # Text color
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
  home.packages = with pkgs; [
    (writeShellApplication {
      name = "swappy-fixed";
      runtimeInputs = [
        pkgs.swappy
        pkgs.gnugrep
      ];
      text = ''
        export GDK_SCALE=1
        export GDK_DPI_SCALE=1
        export GTK_THEME=Catppuccin-GTK-Dark
        exec ${pkgs.swappy}/bin/swappy "$@" 2> >(grep -v "Theme parsing error: gtk.css" >&2)
      '';
    })
  ];
}
