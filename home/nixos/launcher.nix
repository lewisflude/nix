{
  pkgs,
  config,
  ...
}: let
  palette =
    (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json")).${config.catppuccin.flavor}.colors;
in {
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
