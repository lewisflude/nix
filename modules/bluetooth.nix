# Bluetooth hardware support
_: {
  flake.modules.nixos.bluetooth = _: {
    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            # Experimental is required by Home Assistant / bleak for the BlueZ
            # AdvertisementMonitor D-Bus API — do not remove.
            Experimental = true;
          };
        };
      };
      enableAllFirmware = true;
    };
    services.blueman.enable = true;
  };
}
