{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  hardware.enableAllFirmware = true;
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
      Enable = "Source,Sink,Media,Socket";
      AutoEnable = true;
    };
  };
}
