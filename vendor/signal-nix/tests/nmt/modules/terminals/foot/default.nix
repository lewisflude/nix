# Signal Design System - Foot Terminal NMT Tests
{
  lib,
  pkgs,
  self,
}:
{
  nmt-foot-basic-dark = {
    name = "foot-basic-dark";
    modules = [
      {
        programs.foot.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          terminals.foot.enable = true;
        };
        nmt.script = ''
          assertFileExists home-files/.config/foot/foot.ini
          assertFileRegex home-files/.config/foot/foot.ini 'background=0f1419'
        '';
      }
    ];
  };

  nmt-foot-basic-light = {
    name = "foot-basic-light";
    modules = [
      {
        programs.foot.enable = true;
        signal = {
          enable = true;
          mode = "light";
          terminals.foot.enable = true;
        };
        nmt.script = ''
          assertFileExists home-files/.config/foot/foot.ini
          assertFileRegex home-files/.config/foot/foot.ini 'background=fefaf5'
        '';
      }
    ];
  };
}
