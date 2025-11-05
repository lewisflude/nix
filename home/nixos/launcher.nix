{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  # Use FULL Catppuccin palette - access all semantic colors
  # Uses catppuccin.nix module palette when available, falls back to direct input access
  catppuccinPalette =
    if lib.hasAttrByPath [ "catppuccin" "sources" "palette" ] config then
      # Use catppuccin.nix module palette if available
      (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
      .${config.catppuccin.flavor}.colors
    else if inputs ? catppuccin then
      # Try to get palette directly from catppuccin input
      # catppuccin/nix repository has palette.json at the root
      let
        catppuccinSrc = inputs.catppuccin.src or inputs.catppuccin.outPath or null;
      in
      if catppuccinSrc != null then
        (pkgs.lib.importJSON (catppuccinSrc + "/palette.json")).mocha.colors
      else
        throw "Cannot find catppuccin source (input exists but src/outPath not found)"
    else
      throw "Cannot find catppuccin: input not available and config.catppuccin.sources.palette not set";

  # Use Catppuccin colors directly for accurate theming
  palette = catppuccinPalette;
in
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "Iosevka:size=12";
        terminal = "${pkgs.ghostty}/bin/ghostty -e";
        layer = "overlay";
        width = 30;
        horizontal-pad = 20;
        vertical-pad = 15;
        inner-pad = 5;
        launch-prefix = "${pkgs.uwsm}/bin/uwsm app --";
        lines = 15;
        line-height = 20;
        letter-spacing = 0;
        image-size-ratio = 0.5;
        prompt = "> ";
        tabs = 4;
        icons-enabled = true;
        match-mode = "fuzzy";
      };
      border = {
        width = 2;
        radius = 10;
      };
      colors = {
        background = palette.base.hex + "ff";
        text = palette.text.hex + "ff";
        match = palette.mauve.hex + "ff";
        selection = palette.surface1.hex + "ff";
        selection-text = palette.text.hex + "ff";
        selection-match = palette.mauve.hex + "ff";
        border = palette.lavender.hex + "ff";
      };
      dmenu = {
        exit-immediately-if-empty = true;
      };
      key-bindings = {
        cancel = "Escape Control+g";
        execute = "Return KP_Enter Control+y";
        execute-or-next = "Tab";
        cursor-left = "Left Control+b";
        cursor-right = "Right Control+f";
        cursor-home = "Home Control+a";
        cursor-end = "End Control+e";
        delete-prev = "BackSpace";
        delete-next = "Delete";
        delete-to-end-of-line = "Control+k";
        prev = "Up Control+p";
        next = "Down Control+n";
        prev-page = "Page_Up";
        next-page = "Page_Down";
      };
    };
  };
}
