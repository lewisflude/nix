{pkgs, ...}: {
  home.packages = with pkgs; [
    vulkan-tools
    mesa-demos
    libva
    libva-utils
    egl-wayland
    nv-codec-headers
  ];
}
