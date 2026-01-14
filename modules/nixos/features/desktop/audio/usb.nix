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
      # Targeted approach: disable autosuspend only for audio class devices
      services.udev.extraRules = ''
        # Disable autosuspend for USB audio (class 01) to prevent dropouts
        ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="01", TEST=="power/control", \
          ATTR{power/control}="on", ATTR{power/wakeup}="disabled", ATTR{power/autosuspend}="-1"

        # Apogee-specific optimization (USB Vendor ID: 0xa07)
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0a07", \
          ATTR{power/control}="on", ATTR{power/wakeup}="disabled", ATTR{power/autosuspend}="-1"
      '';
    })

    # Note: Removed global usbcore.autosuspend=-1 kernel parameter
    # Modern kernels + targeted udev rules are sufficient and more efficient
  ];
}
