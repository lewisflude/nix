{ pkgs, ... }:
{
  home.packages = [
    # OpenGL diagnostics
    pkgs.mesa-demos # glxinfo, glxgears, eglinfo

    # Vulkan diagnostics
    pkgs.vulkan-tools # vulkaninfo, vkcube

    # X11 display information (useful with XWayland)
    pkgs.xorg.xdpyinfo
  ];
}
