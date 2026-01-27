{
  pkgs,
  ...
}:
{
  programs.zellij = {
    enable = true;

    enableZshIntegration = true;


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
