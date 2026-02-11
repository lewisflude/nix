# XWayland Configuration
# Legacy X11 application support on Wayland
_: {
  flake.modules.nixos.xwayland = _: {
    programs.xwayland.enable = true;
  };
}
