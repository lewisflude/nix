# Zellij - Terminal multiplexer
#
# No SSH auto-attach: connection persistence is handled at the transport layer
# by mosh / eternal-terminal, which already survive disconnects, sleep, and
# network changes. Zellij is a manual multiplexer for panes (`zj` / `zellij`),
# so remote shells never mirror-fight over a shared session.
_: {
  flake.modules.homeManager.zellij = {
    programs.zellij = {
      enable = true;
      enableZshIntegration = false;
      settings = {
        copy_clipboard = "system";
        copy_on_select = true;
        osc8_hyperlinks = true;
        scroll_buffer_size = 100000;
      };

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
