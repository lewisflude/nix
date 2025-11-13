{ pkgs, lib, ... }:
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
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
}
