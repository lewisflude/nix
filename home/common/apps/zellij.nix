{
  pkgs,
  lib,
  ...
}: {
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;

    enableZshIntegration = true;

    settings = ''
      theme "default"
      default_mode "locked"
      mouse_mode true
      scroll_rebuffer_on_resize true
      pane_frames true
      copy_on_select true

      keybinds {
        normal {
          bind "Alt-h" { MoveFocusLeft; }
          bind "Alt-l" { MoveFocusRight; }
          bind "Alt-k" { MoveFocusUp; }
          bind "Alt-j" { MoveFocusDown; }

          bind "Alt-H" { ResizeLeft; }
          bind "Alt-L" { ResizeRight; }
          bind "Alt-K" { ResizeUp; }
          bind "Alt-J" { ResizeDown; }

          bind "Alt-d" { SplitRight; }
          bind "Alt-s" { SplitDown; }

          bind "Alt-n" { NewPane; }
          bind "Alt-t" { NewTab; }
        }
      }
    '';

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
