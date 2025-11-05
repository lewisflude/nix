{ pkgs, ... }:
{
  home.packages = with pkgs; [
    usbutils
    evhz
    piper
  ];
  services.udiskie = {
    enable = true;
    settings = {
      program_options = {
        file_manager = "${pkgs.xfce.thunar}/bin/thunar";
      };
    };
  };
}
