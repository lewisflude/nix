{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.host.features.desktop;
in {
  config = lib.mkIf cfg.enable {
    environment.pathsToLink = ["/share/wayland-sessions"];
    time.timeZone = "Europe/London";
    programs.niri.enable = true;
    programs.uwsm = {
      enable = true;
      waylandCompositors = {
        niri = {
          prettyName = "Niri (UWSM)";
          comment = "Niri compositor managed by UWSM";
          binPath = pkgs.writeShellScript "niri" ''
            ${lib.getExe config.programs.niri.package} --session
          '';
        };
      };
    };
    services = {
      greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --remember --time --time-format '%I:%M %p | %a • %h | %F'";
            user = "greeter";
          };
        };
      };
      # colord.enable = true; # TEMPORARILY DISABLED: testing for webkitgtk dependency
    };
  };
}
