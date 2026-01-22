# Kernel Configuration for Audio
# ALSA sequencer module blacklisting, CPU frequency governor, and pro audio optimizations
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.media.audio;
in
{
  config = mkIf cfg.enable {
    # Blacklist ALSA sequencer kernel modules to prevent PipeWire crashes
    # These modules cause snd_seq_event_input crashes in PipeWire < 1.4.10
    # Since we're disabling alsa.seq in PipeWire config, we don't need these
    # TODO: Remove this workaround after nixpkgs updates to PipeWire 1.4.10+
    boot.blacklistedKernelModules = [
      "snd_seq"
      "snd_seq_dummy"
      "snd_seq_midi"
      "snd_seq_midi_event"
    ];

    # Pro Audio kernel parameters
    # Based on Arch Wiki Professional Audio recommendations
    boot.kernelParams = [
      # Force all IRQs to be threaded for better realtime performance
      # This is critical for low-latency audio and is enabled by default in RT kernels
      # XanMod kernel benefits from this for audio workloads
      "threadirqs"
    ];

    # CPU frequency governor for stable audio performance
    # Use "performance" ONLY with realtime=true (RT kernel)
    # For non-RT kernels (XanMod), schedutil provides good latency with better efficiency
    powerManagement.cpuFreqGovernor = if cfg.realtime then "performance" else lib.mkDefault "schedutil";

    # RTC (Real-Time Clock) interrupt frequency settings
    # Increases the highest requested RTC interrupt frequency from default 64 Hz to 2048 Hz
    # This improves timing precision for audio applications
    # Based on: https://wiki.archlinux.org/title/Professional_audio#Optimizing_system_configuration
    systemd.services.increase-rtc-frequency = {
      description = "Increase RTC interrupt frequency for pro audio";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "increase-rtc-freq" ''
          # Set RTC max frequency to 2048 Hz (default is 64 Hz)
          echo 2048 > /sys/class/rtc/rtc0/max_user_freq || true
          # Set HPET max frequency to 2048 Hz if available
          if [ -f /proc/sys/dev/hpet/max-user-freq ]; then
            echo 2048 > /proc/sys/dev/hpet/max-user-freq || true
          fi
        '';
      };
    };
  };
}
