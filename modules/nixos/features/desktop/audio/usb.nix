# USB Audio Optimizations
# USB autosuspend prevention for professional audio interfaces
{
  config,
  lib,
  pkgs,
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

      # PCI latency timer optimization for audio devices
      # Based on Arch Wiki Pro Audio recommendations
      # Maximizes latency timer for audio devices to prevent buffer underruns
      systemd.services.optimize-pci-latency = {
        description = "Optimize PCI latency timers for audio devices";
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user.target" ];
        path = [ pkgs.pciutils ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "optimize-pci-latency" ''
            # Set default PCI latency timer to 176 (0xb0) for all devices
            setpci -v -d '*:*' latency_timer=b0 || true

            # Find audio devices (class 04xx) and set maximum latency (255/0xff)
            for device in $(lspci -n | awk '/04[0-9][0-9]:/ {print $1}'); do
              echo "Maximizing latency timer for audio device: $device"
              setpci -v -s "$device" latency_timer=ff || true
            done
          '';
        };
      };

      # WirePlumber configuration for USB audio devices
      # Based on Arch Wiki recommendations for USB DAC latency reduction
      services.pipewire.wireplumber.extraConfig."10-usb-audio-optimization"."monitor.alsa.rules" = [
        {
          # USB audio interface optimizations (Apogee Symphony Desktop)
          matches = [
            { "node.name" = "~alsa_output.usb-Apogee.*"; }
            { "node.name" = "~alsa_input.usb-Apogee.*"; }
          ];
          actions.update-props = {
            # Use native S24_3LE format if supported (check with: cat /proc/asound/card*/stream*)
            # This reduces latency with some USB DACs
            # "audio.format" = "S24_3LE"; # Uncomment if your DAC supports it
            "audio.rate" = 96000; # Match Apogee's native rate
            "api.alsa.period-size" = 128; # Lower latency for USB
            "api.alsa.headroom" = 2048; # Smaller headroom for USB
            "session.suspend-timeout-seconds" = 0;
          };
        }
      ];
    })

    # Note: Removed global usbcore.autosuspend=-1 kernel parameter
    # Modern kernels + targeted udev rules are sufficient and more efficient
  ];
}
