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
    ./desktop-environment.nix
    ./graphics.nix
    ./hyprland.nix
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
    ];
  };
}
