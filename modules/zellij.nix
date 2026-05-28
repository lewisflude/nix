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
          # Eternal Terminal reconnects transport state, but iOS clients can lose
          # their per-session ET key when the app or tab is suspended. Keep the
          # actual work anchored in a server-side multiplexer.
          if [[ -o interactive \
            && -n "''${ET_VERSION:-}" \
            && -z "''${ZELLIJ:-}" \
            && -z "''${ET_NO_ZELLIJ:-}" \
            && -t 0 \
            && -t 1 ]] && command -v zellij >/dev/null 2>&1; then
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
            exec zellij attach -c eternal-terminal
          fi
        ''
      );
    };
}
