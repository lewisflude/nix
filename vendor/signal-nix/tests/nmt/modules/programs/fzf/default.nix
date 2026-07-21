# Signal Design System - FZF NMT Tests
{
  lib,
  pkgs,
  self,
}:
{
  nmt-fzf-basic-dark = {
    name = "fzf-basic-dark";
    modules = [
      {
        programs.fzf.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          cli.fzf.enable = true;
        };
        nmt.script = ''
          assertFileRegex home-files/.bashrc 'FZF_DEFAULT_OPTS'
          assertFileRegex home-files/.bashrc '--color='
        '';
      }
    ];
  };

  nmt-fzf-basic-light = {
    name = "fzf-basic-light";
    modules = [
      {
        programs.fzf.enable = true;
        signal = {
          enable = true;
          mode = "light";
          cli.fzf.enable = true;
        };
        nmt.script = ''
          assertFileRegex home-files/.bashrc 'FZF_DEFAULT_OPTS'
        '';
      }
    ];
  };
}
