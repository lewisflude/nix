# Greeter Configuration
# greetd with DMS greeter and (optionally) auto-login.
# Composition is dendritic: import nixos.greeter alone for the login screen,
# or also import nixos.greeterAutoLogin to skip the screen and auto-login as host.username.
# Follows: https://danklinux.com/docs/dankmaterialshell/nixos-flake
{ inputs, ... }:
{
  flake.modules.nixos.greeter =
    { config, ... }:
    {
      # https://danklinux.com/docs/dankmaterialshell/home-manager#greeter-options
      programs.dank-material-shell.greeter = {
        enable = true;
        compositor.name = "niri";
        logs = {
          save = true;
          path = "/tmp/dms-greeter.log";
        };
        configHome = "/home/${config.host.username}";
      };
    };

  flake.modules.nixos.greeterAutoLogin =
    { pkgs, config, ... }:
    let
      niri = inputs.niri.packages.${config.nixpkgs.hostPlatform.system}.niri-unstable;
      session = {
        command = "${pkgs.uwsm}/bin/uwsm start -- ${niri}/bin/niri-session";
        user = config.host.username;
      };
    in
    {
      services.greetd.settings = {
        initial_session = session;
        default_session = session;
      };
    };
}
