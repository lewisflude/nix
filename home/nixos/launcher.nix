{
  pkgs,
  ...
}:
let
  # Scientific Theme - Dark Mode Palette
  palette = {
    base = "#1e1f26"; # base-L015
    surface = "#2d2e39"; # surface-Lc10
    text = "#c0c3d1"; # text-Lc75
    purple = "#a368cf"; # Lc75-h290 (Special)
    blue = "#5a7dcf"; # Lc75-h240 (Focus)
  };
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
        background = palette.base + "ff";
        text = palette.text + "ff";
        match = palette.purple + "ff";
        selection = palette.surface + "ff";
        selection-text = palette.text + "ff";
        selection-match = palette.purple + "ff";
        border = palette.blue + "ff";
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
