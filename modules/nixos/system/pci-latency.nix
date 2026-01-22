# PCI Express Latency Tuning
# Based on Arch Wiki Gaming optimizations and CachyOS settings
# https://wiki.archlinux.org/title/Gaming#Improve_PCI_Express_Latencies
#
# Reduces maximum cycles a PCI-E client can occupy the bus.
# Improves responsiveness by preventing long bus occupancy.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixosConfig.pciLatency;
in
{
  options.nixosConfig.pciLatency = {
    enable = lib.mkEnableOption "PCI Express latency tuning for gaming";

    defaultLatency = lib.mkOption {
      type = lib.types.int;
      default = 32; # CachyOS uses 20, but 32 is safer default
      description = ''
        Default PCI latency timer value for most devices (in PCI clock cycles).
        Lower = more frequent bus arbitration = lower latency for other devices.
        Range: 0-248 (in units of 8 PCI clocks). Default: 32.
      '';
    };

    hostBridgeLatency = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = ''
        PCI latency timer for host bridge (bus 0, device 0).
        Should be 0 as host bridge doesn't need bus time.
      '';
    };

    audioLatency = lib.mkOption {
      type = lib.types.int;
      default = 80;
      description = ''
        PCI latency timer for audio devices (class 04xx).
        Higher priority for audio to prevent dropouts/crackling.
        Range: 0-248. Default: 80.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Create systemd service to set PCI latency timers at boot
    systemd.services.pci-latency-tuning = {
      description = "PCI Express Latency Tuning";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Wait for PCI devices to settle
        ${pkgs.coreutils}/bin/sleep 2

        # Set default latency for all PCI devices
        # Using -qq to suppress output unless there's an error
        ${pkgs.pciutils}/bin/setpci -v -s '*:*' latency_timer=${toString cfg.defaultLatency} 2>&1 | \
          ${pkgs.gnugrep}/bin/grep -v "^$" || true

        # Host bridge (bus 0, device 0) gets latency 0
        ${pkgs.pciutils}/bin/setpci -v -s '0:0' latency_timer=${toString cfg.hostBridgeLatency} 2>&1 | \
          ${pkgs.gnugrep}/bin/grep -v "^$" || true

        # Audio devices (class 04xx) get higher latency for priority
        ${pkgs.pciutils}/bin/setpci -v -d '*:*:04xx' latency_timer=${toString cfg.audioLatency} 2>&1 | \
          ${pkgs.gnugrep}/bin/grep -v "^$" || true

        echo "PCI latency tuning complete"
      '';
    };
  };
}
