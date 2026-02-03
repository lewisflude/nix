# Greeter Configuration
# greetd with DMS greeter and auto-login support
# Follows: https://danklinux.com/docs/dankmaterialshell/nixos-flake
{ config, inputs, ... }:
let
  inherit (config) username;
in
{
  flake.modules.nixos.greeter =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      # Enable DMS greeter for greetd
      # https://danklinux.com/docs/dankmaterialshell/home-manager#greeter-options
      programs.dank-material-shell.greeter = {
        enable = true;
        compositor = {
          name = "niri";
        };
        logs = {
          save = true;
          path = "/tmp/dms-greeter.log";
        };
        # configHome is the user's home directory where DMS finds ~/.config/DankMaterialShell/
        configHome = "/home/${config.host.username}";
      };

      # Greetd auto-login configuration (applied when host.features.desktop.autoLogin.enable = true)
      services.greetd = lib.mkIf config.host.features.desktop.autoLogin.enable {
        settings = {
          initial_session = {
            command = "${pkgs.niri}/bin/niri-session";
            user = config.host.features.desktop.autoLogin.user;
          };
        };
      };
    };
}
