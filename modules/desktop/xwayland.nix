# XWayland Configuration
# Legacy X11 application support on Wayland
{ config, ... }:
{
  flake.modules.nixos.xwayland = { lib, ... }: {
    programs.xwayland.enable = true;
  };
}
