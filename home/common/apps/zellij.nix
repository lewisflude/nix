{
  pkgs,
  ...
}:
{
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableZshIntegration = false;

    settings = {
      default_mode = "locked";
      mouse_mode = true;
      scroll_buffer_size = 100000;
      scroll_rebuffer_on_resize = true;
      pane_frames = true;
      copy_on_select = true;

      session_serialization = true;
      simplified_ui = false;
      on_force_close = "quit";
    };

    extraConfig = builtins.readFile ./zellij-config.kdl;

    layouts.default = ''
      layout {
        pane focus=true {
          cwd "~"
          command "zsh"
        }
      }
    '';
  };
}
