# Zellij - Terminal multiplexer
{ config, ... }:
{
  flake.modules.homeManager.zellij =
    { ... }:
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
    };
}
