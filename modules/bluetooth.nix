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

    # Intel AX210 (8087:0032). Home Assistant's bluetooth integration recovers a
    # wedged controller in two stages: a power cycle over the mgmt socket, then a
    # USB port reset if that was not enough. The first stage works — it fired
    # successfully on 2026-08-23 15:45:55 after `hci0: Opcode 0x2042 failed:
    # -112`, because home-assistant.service already carries CAP_NET_ADMIN and
    # CAP_NET_RAW. The second stage died with `permission denied to
    # /dev/bus/usb/001/005`: the raw USB node is root:root 0664 and hass is not
    # root. Hand the device to the hass group so the deeper reset is available
    # the day the soft one is not enough.
    #
    # The -112 (ETIMEDOUT) itself is a once-in-seven-weeks transient — three
    # lines across 50 boots — not the known AX210 regressions (0xfc05 tx timeout
    # /-110 on warm reboot, or the 6.10-rc1 ext-scan bug). It is HA's own bleak
    # AdvertisementMonitor churn racing the controller, so no kernel param,
    # btusb option or firmware change is warranted; disabling background
    # scanning would break the integration this exists to serve.
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="8087", ATTR{idProduct}=="0032", GROUP="hass", MODE="0660"
    '';
  };
}
