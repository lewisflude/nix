{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    loginShellInit = ''
      export SHELL=${pkgs.zsh}/bin/zsh
    '';
  };
}
