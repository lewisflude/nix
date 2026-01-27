{
  pkgs,
  ...
}:
{
  programs.zellij = {
    enable = true;

    enableZshIntegration = false;

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
