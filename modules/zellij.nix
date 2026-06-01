# Zellij - Terminal multiplexer
_: {
  flake.modules.homeManager.zellij =
    { config, lib, ... }:
    {
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

      programs.zsh.initContent = lib.mkIf config.programs.zsh.enable (
        lib.mkBefore ''
          # Anchor remote interactive shells in one server-side zellij session.
          if [[ $- == *i* && -z "''${ZELLIJ:-}" && -z "''${NO_AUTO_ZELLIJ:-}" \
            && ( -n "''${SSH_CONNECTION:-}" || -n "''${SSH_TTY:-}" || -n "''${ET_VERSION:-}" ) ]] \
            && command -v zellij >/dev/null 2>&1; then
            exec zellij attach -c remote
          fi
        ''
      );
    };
}
