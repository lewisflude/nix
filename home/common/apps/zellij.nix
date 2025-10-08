{ config
, pkgs
, lib
, ...
}: {
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;

    settings = {
      theme = lib.mkForce "default";
      default_mode = "locked";
      mouse_mode = true;
      scroll_rebuffer_on_resize = true;

      pane_frames = true;
      copy_on_select = true;

      keybinds = {
        normal = [
          {
            bind = "Alt-h";
            action = "MoveFocusLeft";
          }
          {
            bind = "Alt-l";
            action = "MoveFocusRight";
          }
          {
            bind = "Alt-k";
            action = "MoveFocusUp";
          }
          {
            bind = "Alt-j";
            action = "MoveFocusDown";
          }

          {
            bind = "Alt-H";
            action = "ResizeLeft";
          }
          {
            bind = "Alt-L";
            action = "ResizeRight";
          }
          {
            bind = "Alt-K";
            action = "ResizeUp";
          }
          {
            bind = "Alt-J";
            action = "ResizeDown";
          }

          {
            bind = "Alt-d";
            action = "SplitRight";
          }
          {
            bind = "Alt-s";
            action = "SplitDown";
          }

          {
            bind = "Alt-n";
            action = "NewPane";
          }
          {
            bind = "Alt-t";
            action = "NewTab";
          }
        ];
      };
    };

    enableZshIntegration = true;
  };

  home.file.".config/zellij/layouts/default.kdl".text = ''
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
}
