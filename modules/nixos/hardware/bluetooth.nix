{
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
          Enable = "Source,Sink,Media,Socket";
          AutoEnable = true;
        };
      };
    };
    enableAllFirmware = true;
  };

  services.blueman.enable = true;
}
