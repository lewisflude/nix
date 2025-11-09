{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let

      palette = {

        rosewater = "#f5e0dc";

        flamingo = "#f2cdcd";

        pink = "#f5c2e7";

        mauve = "#cba6f7";

        red = "#f38ba8";

        maroon = "#eba0ac";

        peach = "#fab387";

        yellow = "#f9e2af";

        green = "#a6e3a1";

        teal = "#94e2d5";

        sky = "#89dceb";

        sapphire = "#74c7ec";

        blue = "#89b4fa";

        lavender = "#b4befe";

        text = "#cdd6f4";

        subtext1 = "#bac2de";

        subtext0 = "#a6adc8";

        overlay2 = "#9399b2";

        overlay1 = "#7f849c";

        overlay0 = "#6c7086";

        surface2 = "#585b70";

        surface1 = "#45475a";

        surface0 = "#313244";

        base = "#1e1e2e";

        mantle = "#181825";

        crust = "#11111b";

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
