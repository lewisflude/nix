# USB Audio Optimizations
# Generic USB autosuspend prevention for professional audio interfaces
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.media.audio;
in
{
  config = mkIf cfg.enable {
    # Disable USB autosuspend for all USB audio class devices to prevent dropouts
    # Targeted approach: only affects USB audio (class 01) devices
    services.udev.extraRules = ''
      # Disable autosuspend for USB audio (class 01) to prevent dropouts
      ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="01", TEST=="power/control", \
        ATTR{power/control}="on", ATTR{power/wakeup}="disabled", ATTR{power/autosuspend}="-1"
    '';

    # Note: Device-specific optimizations (Apogee, etc.) should be in host-specific configs
    # Note: Removed global usbcore.autosuspend=-1 kernel parameter (too broad)
    # Note: Removed PCI latency tuning (premature optimization)
  };
}
