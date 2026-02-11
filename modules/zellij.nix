# Zellij - Terminal multiplexer
_:
{
  flake.modules.homeManager.zellij =
    _:
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
