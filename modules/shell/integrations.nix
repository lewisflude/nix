# Shell tool integrations: directory jumping, fuzzy finding, history, direnv.
#
# All of these hook into .zshrc at home-manager's default order (1000), between
# compinit and the mkAfter block — see the ordering contract in zsh.nix.
_: {
  flake.modules.homeManager.shell =
    { lib, pkgs, ... }:
    {
      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
        options = [ "--cmd cd" ];
      };

      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        # No flags: ATUIN_NOBIND (zsh.nix localVariables) already suppresses
        # every binding, which made --disable-up-arrow a no-op. ^r is bound
        # explicitly at order 1500.
        settings.sync_frequency = "5m";
      };

      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
        # Replaces the DIRENV_LOG_FORMAT="" environment hack, which was set in
        # three places with two conflicting DIRENV_WARN_TIMEOUT values.
        silent = true;
        stdlib = ''
          layout_zellij() {
            [ -n "$ZELLIJ" ] && return 0

            local session_name
            session_name="$(basename "$PWD")"

            if [ -f ".zellij.kdl" ]; then
              exec zellij --layout .zellij.kdl attach -c "$session_name"
            else
              exec zellij attach -c "$session_name"
            fi
          }
        '';
      };

      programs.nix-your-shell = {
        enable = true;
        enableZshIntegration = true;
      };

      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
        defaultOptions = [
          "--height 40%"
          "--border"
        ];
        # fd is unconditional in cliApps, so the old `if pkgs ? fd then ... else
        # if pkgs ? ripgrep then ... else null` fallback chain could never fire.
        defaultCommand = "${lib.getExe pkgs.fd} --hidden --strip-cwd-prefix --exclude .git";
        fileWidget.command = "${lib.getExe pkgs.fd} --type f --hidden --strip-cwd-prefix --exclude .git";
        # Atuin owns ^r (bound explicitly at order 1500 in zsh.nix). This is
        # home-manager's supported way to yield the binding to a history
        # manager; without it fzf also binds ^r and eval emits a conflict
        # warning that the order-1500 rebind only papers over.
        historyWidget.zsh.command = "";
      };
    };
}
