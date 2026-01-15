# Power button widget - triggers fuzzel power menu
# Uses shared power-menu script (DRY - same logic as Mod+X keybind)
{ pkgs }:
let
  # Shared power menu script - single source of truth
  # Referenced by both this widget and Niri's Mod+X keybind
  powerMenuScript = pkgs.writeShellScript "power-menu" ''
    OPTIONS="Logout
    Suspend
    Hibernate
    Reboot
    Shutdown"

    CHOICE=$(echo "$OPTIONS" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt 'Power: ')

    case "$CHOICE" in
      Logout) ${pkgs.niri}/bin/niri msg action quit ;;
      Suspend) ${pkgs.systemd}/bin/systemctl suspend ;;
      Hibernate) ${pkgs.systemd}/bin/systemctl hibernate ;;
      Reboot) ${pkgs.systemd}/bin/systemctl reboot ;;
      Shutdown) ${pkgs.systemd}/bin/systemctl poweroff ;;
    esac
  '';
in
{
  type = "custom";
  class = "power-btn";
  bar = [
    {
      type = "button";
      class = "power-btn";
      label = "";
      on_click = "${powerMenuScript}";
      tooltip = "Power Menu (Logout/Suspend/Reboot/Shutdown)";
    }
  ];
}
