{ pkgs, username, ... }:
{
  environment.systemPackages = with pkgs; [
    wofi
    tuigreet
    sway
    gtk4
  ];

  time.timeZone = "Europe/London";

  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      niri = {
        prettyName = "Niri";
        comment = "Niri compositor managed by UWSM";
        binPath = "${pkgs.niri-unstable}/bin/niri-session";
      };
    };
  };

  services = {
    greetd = {
      enable = true;
      settings = {
        initial_session = {
          command = "${pkgs.uwsm}/bin/uwsm start niri-uwsm.desktop";
          user = username;
        };
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --remember --time --time-format '%I:%M %p | %a • %h | %F'";
          user = "greeter";
        };
      };
    };
  };
}
