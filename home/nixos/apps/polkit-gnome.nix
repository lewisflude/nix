{ lib, ... }:
{
  services.polkit-gnome.enable = true;

  # Mask niri-flake's polkit-kde-agent service in favor of polkit-gnome
  # This prevents it from starting even if defined by niri-flake
  systemd.user.services.niri-flake-polkit.Unit.ConditionPathExists = lib.mkForce "/nonexistent";
}
