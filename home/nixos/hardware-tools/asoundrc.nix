_: {
  # User-level ALSA configuration to ensure consistent device selection
  # This is the PROPER place for user audio preferences (not system-level)
  home.file.".asoundrc".text = ''
    # Set default card to "default" (which uses PipeWire)
    # This ensures apps preferentially use PipeWire routing
    defaults.pcm.card "default"
    defaults.ctl.card "default"

    # Ensure "default" device uses PipeWire with WirePlumber's configured sink
    pcm.!default {
      type pipewire
      playback_node "-1"  # -1 = use WirePlumber's default (Speakers sink)
      capture_node "-1"
      hint {
        show on
        description "Default Audio (PipeWire)"
      }
    }

    ctl.!default {
      type pipewire
    }
  '';
}
