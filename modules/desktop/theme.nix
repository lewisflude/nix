# Theme Configuration
# System-wide theming via Signal NixOS modules
{ config, ... }:
{
  flake.modules.nixos.theme = { pkgs, lib, config, ... }: {
    theming.signal.nixos = lib.mkIf config.host.features.desktop.signalTheme.enable {
      enable = true;
      autoEnable = true;
      mode = config.host.features.desktop.signalTheme.mode;
    };
  };
}
