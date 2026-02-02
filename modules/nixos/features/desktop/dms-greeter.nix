{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{
  config = lib.mkIf (cfg.enable && cfg.greeter == "dms") {
    # Enable DMS greeter for greetd
    programs.dank-material-shell.greeter = {
      enable = true;

      # Use niri as the compositor for the greeter
      compositor = {
        name = "niri";
        # Optional: Add custom compositor config if needed
        # customConfig = [];
      };

      # Enable logging for troubleshooting
      logs = {
        save = true;
        path = "/tmp/dms-greeter.log";
      };

      # Use config from user's home directory
      configHome = "/home/${config.host.username}/.config/dms";
    };
  };
}
