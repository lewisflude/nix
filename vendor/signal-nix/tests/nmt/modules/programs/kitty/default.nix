# Signal Design System - Kitty Terminal NMT Tests
{
  lib,
  pkgs,
  self,
}:
{
  nmt-kitty-basic-dark = {
    name = "kitty-basic-dark";
    modules = [
      {
        programs.kitty.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          terminals.kitty.enable = true;
        };
        nmt.script = ''
          assertFileExists home-files/.config/kitty/kitty.conf
          assertFileRegex home-files/.config/kitty/kitty.conf 'background #0f1419'
          assertFileRegex home-files/.config/kitty/kitty.conf 'foreground #e6e1cf'
        '';
      }
    ];
  };

  nmt-kitty-basic-light = {
    name = "kitty-basic-light";
    modules = [
      {
        programs.kitty.enable = true;
        signal = {
          enable = true;
          mode = "light";
          terminals.kitty.enable = true;
        };
        nmt.script = ''
          assertFileExists home-files/.config/kitty/kitty.conf
          assertFileRegex home-files/.config/kitty/kitty.conf 'background #fefaf5'
        '';
      }
    ];
  };
}
