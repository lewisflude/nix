{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{

  config = lib.mkIf cfg.enable {
    # Enable Signal NixOS theming
    # This provides system-wide GTK theme for login screens, pinentry, etc.
    theming.signal.nixos = {
      enable = true;
      autoEnable = true;
      mode = "dark";
    };
  };
}
