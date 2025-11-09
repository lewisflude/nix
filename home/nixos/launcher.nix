{
  pkgs,
  lib,
  themeContext ? null,
  ...
}:
let
  # Import shared palette (single source of truth) for fallback
  themeHelpers = import ../../modules/shared/features/theming/helpers.nix { inherit lib; };
  themeImport = themeHelpers.importTheme {
    repoRootPath = ../..;
  };
  fallbackTheme = themeImport.generateTheme "dark";

  # Use Signal theme if available, otherwise use fallback from shared palette
  inherit (themeContext.theme or fallbackTheme) colors;
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
        background = colors."surface-base".hex + "ff";
        text = colors."text-primary".hex + "ff";
        match = colors."accent-special".hex + "ff";
        selection = colors."surface-emphasis".hex + "ff";
        selection-text = colors."text-primary".hex + "ff";
        selection-match = colors."accent-special".hex + "ff";
        border = colors."accent-focus".hex + "ff";
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
