{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{
  imports = [
    ./audio.nix
    ./desktop-environment.nix
    ./fonts.nix
    ./graphics.nix
    ./hardware-support.nix
    ./niri.nix
    ./theme.nix
    ./xwayland.nix
  ];

  config = lib.mkIf cfg.enable {
    users.users.${config.host.username}.extraGroups = [
      "audio"
      "video"
      "input"
      "networkmanager"
      "seat" # Required for seatd.sock access (Wayland seat management)
    ];
  };
}
