_: {
  # Enable QMK/VIA/VIAL keyboard support
  hardware.keyboard.qmk.enable = true;

  # Additional udev rules for keyboard programming access
  services.udev.extraRules = ''
    # VIA/VIAL keyboard access
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"

    # QMK bootloader modes
    # Atmel DFU
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff4", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ffb", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff0", MODE="0666", TAG+="uaccess", TAG+="udev-acl"

    # STM32 DFU
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0666", TAG+="uaccess", TAG+="udev-acl"

    # BootloadHID
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="05df", MODE="0666", TAG+="uaccess", TAG+="udev-acl"

    # USBasp
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="05dc", MODE="0666", TAG+="uaccess", TAG+="udev-acl"

    # ModemManager should ignore QMK devices
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff4", ENV{ID_MM_DEVICE_IGNORE}="1"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ffb", ENV{ID_MM_DEVICE_IGNORE}="1"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff0", ENV{ID_MM_DEVICE_IGNORE}="1"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", ENV{ID_MM_DEVICE_IGNORE}="1"
  '';

  # Ensure user is in the input group for device access
  users.groups.input = { };
}
