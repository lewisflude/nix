# Application Launcher Keybindings
# Application shortcuts and launchers
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) getExe;

  # Helper: Launch app via uwsm
  uwsmApp = app: [
    (getExe pkgs.uwsm)
    "app"
    "--"
    app
  ];

  # Helper: Launch terminal with command
  termWith = cmd: [
    (getExe pkgs.ghostty)
    "-e"
    cmd
  ];

  # Helper: Launch terminal with multiple arguments
  termWithArgs =
    args:
    [
      (getExe pkgs.ghostty)
      "-e"
    ]
    ++ args;

  # Common programs
  terminal = getExe pkgs.ghostty;
  launcher = uwsmApp (getExe pkgs.fuzzel);
in
{
  # Terminal shortcuts
  "F13".action.spawn = [ terminal ];
  "Mod+T".action.spawn = [ terminal ];

  # Launcher
  "Mod+D".action.spawn = launcher;

  # GUI applications (via uwsm)
  "Mod+B".action.spawn = uwsmApp (getExe pkgs.chromium);
  "Mod+Ctrl+O".action.spawn = uwsmApp (getExe pkgs.obsidian);
  "Mod+M".action.spawn = uwsmApp (getExe pkgs.thunderbird);

  # Terminal-based applications
  "Mod+E".action.spawn = termWith "yazi";
  "Mod+Shift+O".action.spawn = termWithArgs [
    (getExe pkgs.helix)
    "${config.home.homeDirectory}/.config/nix"
  ];

  # Clipboard history
  "Mod+V".action.spawn = [
    "sh"
    "-c"
    "cliphist list | fuzzel --dmenu | cliphist decode"
  ];
}
