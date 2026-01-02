{ pkgs, ... }:
{
  home.packages = [
    pkgs.usbutils
    pkgs.evhz
    pkgs.piper
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
