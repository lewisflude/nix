# Greeter Configuration
# greetd with auto-login support
{ config, inputs, ... }:
let
  inherit (config) username;
in
{
  flake.modules.nixos.greeter =
    nixosArgs:
    let
      inherit (nixosArgs) pkgs lib;
      nixosConfig = nixosArgs.config;
    in
    {
      # Enable DMS greeter for greetd
      programs.dank-material-shell.greeter = {
        enable = true;
        compositor = {
          name = "niri";
        };
        logs = {
          save = true;
          path = "/tmp/dms-greeter.log";
        };
        configHome = "/home/${nixosConfig.host.username}/.config/dms";
      };

      # Greetd auto-login configuration (applied when host.features.desktop.autoLogin.enable = true)
      services.greetd = lib.mkIf nixosConfig.host.features.desktop.autoLogin.enable {
        settings = {
          initial_session = {
            command = "${pkgs.niri}/bin/niri-session";
            user = nixosConfig.host.features.desktop.autoLogin.user;
          };
        };
      };
    };
}
