{ pkgs, ... }:
let
  yaziWlClipboardSrc = pkgs.fetchFromGitHub {
    owner = "grappas";
    repo = "wl-clipboard.yazi";
    rev = "c4edc4f6adf088521f11d0acf2b70610c31924f0B";
    sha256 = "sha256-jlZgN93HjfK+7H27Ifk7fs0jJaIdnOyY1wKxHz1wX2c=";
  };
in
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      manager = {
        show_hidden = true;
      };
      preview = {
        max_width = 1000;
        max_height = 1000;
      };
    };
    plugins = {
      wl-clipboard = yaziWlClipboardSrc;
    };
    keymap = {
      manager.prepend_keymap = [{
        on = "<C-y>";
        run = [
          "shell -- for path in \"$@\"; do echo \"file://$path\"; done | wl-copy -t text/uri-list"
          "yank"
        ];
      }];
    };
  };
}