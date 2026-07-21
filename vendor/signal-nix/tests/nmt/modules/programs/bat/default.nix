# Signal Design System - Bat NMT Tests
{
  lib,
  pkgs,
  self,
}:
{
  nmt-bat-basic-dark = {
    name = "bat-basic-dark";
    modules = [
      {
        programs.bat.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          cli.bat.enable = true;
        };
        nmt.script = ''
          assertFileExists home-files/.config/bat/config
          assertFileRegex home-files/.config/bat/config '--theme="signal-dark"'
        '';
      }
    ];
  };

  nmt-bat-basic-light = {
    name = "bat-basic-light";
    modules = [
      {
        programs.bat.enable = true;
        signal = {
          enable = true;
          mode = "light";
          cli.bat.enable = true;
        };
        nmt.script = ''
          assertFileExists home-files/.config/bat/config
          assertFileRegex home-files/.config/bat/config '--theme="signal-light"'
        '';
      }
    ];
  };
}
