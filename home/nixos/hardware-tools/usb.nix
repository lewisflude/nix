{ pkgs, ... }:
{
  home.packages = [
    pkgs.usbutils
    # pkgs.evhz  # Temporarily disabled due to compilation errors with glibc 2.40
    pkgs.piper
    pkgs.evemu # Required by wayland-mcp for mouse device detection
    pkgs.android-tools # ADB and fastboot for Android devices
  ];
  services.udiskie = {
    enable = true;
    settings = {
      program_options = {
        file_manager = "${pkgs.thunar}/bin/thunar";
      };
    };
  };
}
