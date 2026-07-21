# Signal Design System - WezTerm NMT Tests
{
  lib,
  pkgs,
  self,
}:
{
  nmt-wezterm-basic-dark = {
    name = "wezterm-basic-dark";
    modules = [
      {
        programs.wezterm.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          terminals.wezterm.enable = true;
        };
        nmt.script = ''
          assertFileExists home-files/.config/wezterm/wezterm.lua
          assertFileRegex home-files/.config/wezterm/wezterm.lua 'signal-dark'
        '';
      }
    ];
  };

  nmt-wezterm-basic-light = {
    name = "wezterm-basic-light";
    modules = [
      {
        programs.wezterm.enable = true;
        signal = {
          enable = true;
          mode = "light";
          terminals.wezterm.enable = true;
        };
        nmt.script = ''
          assertFileExists home-files/.config/wezterm/wezterm.lua
          assertFileRegex home-files/.config/wezterm/wezterm.lua 'signal-light'
        '';
      }
    ];
  };
}
