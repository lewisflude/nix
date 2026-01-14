{ pkgs, ... }:
{
  home.packages = [
    # OpenGL diagnostics and simple benchmarks
    pkgs.mesa-demos # glxinfo, glxgears, eglinfo

    # OpenGL benchmarking suite
    pkgs.glmark2

    # Vulkan benchmarking suite
    pkgs.vkmark

    # X11 display information (useful with XWayland)
    pkgs.xorg.xdpyinfo

    # Note: vulkan-tools (vulkaninfo, vkcube) is already installed
    # at system level in modules/nixos/features/desktop/graphics.nix
  ];
}
