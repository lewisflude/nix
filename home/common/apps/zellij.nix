{
  pkgs,
  lib,
  ...
}: {
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableZshIntegration = true;
    settings = lib.mkForce {
      theme = "default";
      default_mode = "locked";
      mouse_mode = true;
      scroll_buffer_size = 100000;
      scroll_rebuffer_on_resize = true;
      pane_frames = true;
      copy_on_select = true;
      keybinds = {
        normal = {
          "Alt-h" = "MoveFocusLeft";
          "Alt-l" = "MoveFocusRight";
          "Alt-k" = "MoveFocusUp";
          "Alt-j" = "MoveFocusDown";
          "Alt-H" = "ResizeLeft";
          "Alt-L" = "ResizeRight";
          "Alt-K" = "ResizeUp";
          "Alt-J" = "ResizeDown";
          "Alt-d" = "SplitRight";
          "Alt-s" = "SplitDown";
          "Alt-n" = "NewPane";
          "Alt-t" = "NewTab";
        };
      };
    };
    layouts.default = ''
      layout {
        pane focus=true {
          cwd "~"
          command "zsh"
        }
        pane split_direction="vertical" {
          cwd "~"
          command "zsh"
        }
      }
    '';
  };
}
