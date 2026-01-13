# USB Audio Optimizations
# USB autosuspend prevention for professional audio interfaces
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.host.features.media.audio;
in
{
  config = mkMerge [
    (mkIf cfg.enable {
      # USB audio optimizations for professional interfaces
      services.udev.extraRules = ''
        # Disable autosuspend for USB audio (class 01)
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idClass}=="01", TEST=="power/control", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idClass}=="01", ATTR{power/wakeup}="disabled"

        # Apogee-specific (USB Vendor ID: 0xa07)
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0a07", ATTR{power/control}="on", ATTR{power/wakeup}="disabled"
      '';
    })

    (mkIf (cfg.enable && cfg.usbAudioInterface.enable) {
      boot.kernelParams = [
        "usbcore.autosuspend=-1" # Disable USB autosuspend for audio
      ];
    })
  ];
}
