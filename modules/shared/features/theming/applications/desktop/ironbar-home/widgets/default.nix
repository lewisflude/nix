{
  pkgs,
  ...
}:
let
  workspaces = import ./workspaces.nix { };
  focused = import ./focused.nix { };
  clock = import ./clock.nix { };
  sysInfo = import ./sys-info.nix { };
  niriLayout = import ./niri-layout.nix { inherit pkgs; };
  brightness = import ./brightness.nix { };
  volume = import ./volume.nix { };
  tray = import ./tray.nix { };
  notifications = import ./notifications.nix { };
in
{
  start = [
    workspaces
    focused
  ];
  center = [
    clock
  ];
  end = [
    sysInfo
    niriLayout
    brightness
    volume
    tray
    notifications
  ];
}
