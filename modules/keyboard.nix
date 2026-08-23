# Keyboard hardware support (QMK firmware flashing + VIA remapping)
_: {
  flake.modules.nixos.keyboard = {
    # Pulls in pkgs.qmk-udev-rules and creates the plugdev group. Those rules
    # already cover every QMK bootloader (Atmel/STM32 DFU, Caterina, HalfKay,
    # BootloadHID, USBasp, ...) and ship a blanket
    #   KERNEL=="hidraw*", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # which is what VIA/Vial need to reach a board's raw-HID interface.
    #
    # Deliberately NOT adding pkgs.via to services.udev.packages: its rule is
    # the same hidraw match with MODE="0666", which would grant every local
    # user read/write on every hidraw device — YubiKeys and Logitech receivers
    # included. The uaccess tag already ACLs the device to the seat user.
    hardware.keyboard.qmk.enable = true;
  };

  # VIA — GUI remapper. The westfoxtrot prophet runs stock QMK and exposes the
  # raw-HID interface VIA speaks (usage page 0xFF60, usage 0x61). Vial is not
  # an option for it: Vial identifies boards by a "vial:f64c2b3c" USB serial
  # that this firmware does not advertise, so it would need a vial-qmk reflash.
  #
  # Unfree (AppImage, no source release) and x86_64-linux only.
  flake.modules.homeManager.keyboard =
    { lib, pkgs, ... }:
    lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      home.packages = [ pkgs.via ];
    };
}
