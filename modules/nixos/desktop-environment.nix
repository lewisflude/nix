{ pkgs, username, ... }:
{
  environment.systemPackages = with pkgs; [
    wofi
    greetd.tuigreet
    sway
  ];

  time.timeZone = "Europe/London";

  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      hyprland = {
        prettyName = "Hyprland";
        comment = "Hyprland compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/Hyprland";
      };
    };
  };

  services = {
    greetd = {
      enable = true;
      settings = {
        initial_session = {
          command = "${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop";
          user = username;
        };
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --remember --time --time-format '%I:%M %p | %a • %h | %F'";
          user = "greeter";
        };
      };
    };
  };
}
