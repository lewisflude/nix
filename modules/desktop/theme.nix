# Theme Configuration
# System-wide theming via Signal NixOS modules
{ config, ... }:
{
  flake.modules.nixos.theme =
    nixosArgs:
    let
      inherit (nixosArgs) pkgs lib;
      nixosConfig = nixosArgs.config;
    in
    {
      theming.signal.nixos = lib.mkIf nixosConfig.host.features.desktop.signalTheme.enable {
        enable = true;
        autoEnable = true;
        mode = nixosConfig.host.features.desktop.signalTheme.mode;
      };
    };
}
