{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wofi
    greetd.tuigreet
    sway
  ];

  time.timeZone = "Europe/London";
  services = {
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd 'uwsm start hyprland.desktop'";
          user = "greeter";
        };
      };
    };
  };
}
