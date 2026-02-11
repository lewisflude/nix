# FZF - Fuzzy finder
_:
{
  flake.modules.homeManager.fzf =
    { pkgs, lib, ... }:
    {
      programs.fzf = {
        enable = true;
        # Zsh integration disabled - using cached init script in modules/shell.nix for better performance
        enableZshIntegration = false;
        defaultOptions = [
          "--height 40%"
          "--border"
        ];
        defaultCommand = lib.mkDefault (
          if pkgs ? fd then
            "${lib.getExe pkgs.fd} --hidden --strip-cwd-prefix --exclude .git"
          else if pkgs ? ripgrep then
            "${lib.getExe pkgs.ripgrep} --files --hidden --follow --glob '!.git'"
          else
            null
        );
        fileWidgetCommand = lib.mkDefault (
          if pkgs ? fd then
            "${lib.getExe pkgs.fd} --type f --hidden --strip-cwd-prefix --exclude .git"
          else
            null
        );
      };
    };
}
