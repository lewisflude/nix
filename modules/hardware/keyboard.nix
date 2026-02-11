# Keyboard hardware support (QMK, HID)
{ ... }:
{
  flake.modules.nixos.keyboard =
    { ... }:
    {
      hardware.keyboard.qmk.enable = true;

      services.udev.extraRules = ''
        # HID raw device access
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"

        # Atmel DFU bootloader
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff4", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ffb", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff0", MODE="0666", TAG+="uaccess", TAG+="udev-acl"

        # STM32 DFU
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0666", TAG+="uaccess", TAG+="udev-acl"

        # Teensy HalfKay
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="05df", MODE="0666", TAG+="uaccess", TAG+="udev-acl"

        # USBasp
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="05dc", MODE="0666", TAG+="uaccess", TAG+="udev-acl"

        # Ignore ModemManager for these devices
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff4", ENV{ID_MM_DEVICE_IGNORE}="1"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ffb", ENV{ID_MM_DEVICE_IGNORE}="1"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff0", ENV{ID_MM_DEVICE_IGNORE}="1"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", ENV{ID_MM_DEVICE_IGNORE}="1"
      '';

      users.groups.input = { };
    };
}
