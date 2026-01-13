# Application Launcher Keybindings
# Application shortcuts and launchers
{
  config,
  pkgs,
  lib,
  ...
}:
let
  uwsm = lib.getExe pkgs.uwsm;
  terminal = lib.getExe pkgs.ghostty;
  launcher = [
    uwsm
    "app"
    "--"
    (lib.getExe pkgs.fuzzel)
  ];
in
{
  "F13".action.spawn = [ terminal ];

  "Mod+T".action.spawn = terminal;
  "Mod+D".action.spawn = launcher;

  "Mod+B" = {
    action.spawn = [
      uwsm
      "app"
      "--"
      (lib.getExe pkgs.chromium)
    ];
  };

  "Mod+E".action.spawn = [
    "${pkgs.ghostty}/bin/ghostty"
    "-e"
    "yazi"
  ];

  "Mod+Ctrl+O" = {
    action.spawn = [
      uwsm
      "app"
      "--"
      (lib.getExe pkgs.obsidian)
    ];
  };

  "Mod+Shift+O" = {
    action.spawn = [
      terminal
      "-e"
      (lib.getExe pkgs.helix)
      "${config.home.homeDirectory}/.config/nix"
    ];
  };

  "Mod+M" = {
    action.spawn = [
      uwsm
      "app"
      "--"
      (lib.getExe pkgs.thunderbird)
    ];
  };

  "Mod+V" = {
    action.spawn = [
      "sh"
      "-c"
      "cliphist list | fuzzel --dmenu | cliphist decode"
    ];
  };
}
