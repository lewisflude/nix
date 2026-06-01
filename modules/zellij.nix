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
          # Anchor any remote interactive shell (ssh, mosh, Eternal Terminal)
          # in a single server-side zellij session. Gives uniform scrollback
          # and OSC 52 clipboard regardless of transport, and lets reconnects
          # from any client land back in the same session.
          if [[ -o interactive \
            && -z "''${ZELLIJ:-}" \
            && -z "''${NO_AUTO_ZELLIJ:-}" \
            && -t 0 \
            && -t 1 \
            && ( -n "''${ET_VERSION:-}" \
                 || -n "''${SSH_CONNECTION:-}" \
                 || -n "''${SSH_TTY:-}" ) ]] \
            && command -v zellij >/dev/null 2>&1; then
            # iOS Termix over ET reports a narrow COLUMNS that the prompt
            # link rendering can't fit. Only apply the override under ET.
            if [[ -n "''${ET_VERSION:-}" ]]; then
              prompt_link_cols="''${PROMPT_LINK_COLS:-}"
              if [[ -z "$prompt_link_cols" && "''${COLUMNS:-0}" == <-> && "''${COLUMNS:-0}" -lt 100 ]]; then
                prompt_link_cols=240
              fi
              if [[ -n "$prompt_link_cols" \
                && "$prompt_link_cols" != 0 \
                && "$prompt_link_cols" == <-> \
                && "$prompt_link_cols" -ge 80 ]]; then
                command stty cols "$prompt_link_cols" 2>/dev/null || true
                export COLUMNS="$prompt_link_cols"
              fi
              unset prompt_link_cols
            fi
            exec zellij attach -c remote
          fi
        ''
      );
    };
}
