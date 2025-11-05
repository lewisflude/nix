{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gtklock
  ];
  xdg.configFile."gtklock/config".text = ''
    gtk-theme = "Catppuccin-GTK-Dark"
    time-format = "%H:%M:%S"
    date-format = "%A, %B %d"
    idle-hide = true
    idle-timeout = 60
  '';
}
