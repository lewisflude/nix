# Kernel Configuration for Audio
# ALSA sequencer module blacklisting and CPU frequency governor
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
    # Blacklist ALSA sequencer kernel modules to prevent PipeWire crashes
    # These modules cause snd_seq_event_input crashes in PipeWire < 1.4.10
    # Since we're disabling alsa.seq in PipeWire config, we don't need these
    boot.blacklistedKernelModules = [
      "snd_seq"
      "snd_seq_dummy"
      "snd_seq_midi"
      "snd_seq_midi_event"
    ];

    # CPU frequency governor for stable audio performance
    powerManagement.cpuFreqGovernor = "performance";
  };
}
