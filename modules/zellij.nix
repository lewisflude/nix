# Zellij - Terminal multiplexer
_: {
  flake.modules.homeManager.zellij =
    { config, lib, ... }:
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
            exec zellij attach -c eternal-terminal
          fi
        ''
      );
    };
}
