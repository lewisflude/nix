# Music Production - DAWs, trackers, and pro audio optimizations
# Relies on audio.nix for PipeWire/JACK base; adds DAWs, trackers, plugins, and musnix tuning
# References:
# - https://wiki.nixos.org/wiki/Audio_production
# - https://github.com/musnix/musnix
# - https://wiki.nixos.org/wiki/JACK
{ inputs, ... }:
{
  # audio.nix overlay (Bitwig Studio + audio plugins, Linux only).
  # Patches super.webkitgtk → webkitgtk_6_0 because audio-nix expects the older attr name.
  overlays.audio-nix =
    final: super:
    if super.stdenv.hostPlatform.isLinux then
      let
        superWithWebkit =
          super // (if super ? webkitgtk_6_0 then { webkitgtk = super.webkitgtk_6_0; } else { });
      in
      inputs.audio-nix.overlays.default final superWithWebkit
    else
      { };

  # NixOS: realtime audio optimizations via musnix
  flake.modules.nixos.musicProduction = _: {
    # musnix handles: PAM limits (memlock, rtprio), CPU governor,
    # vm.swappiness, udev rules, and plugin path env vars
    musnix = {
      enable = true;
      # Use the existing kernel rather than a realtime one --
      # PipeWire + rtkit is sufficient for most DAW work
      kernel.realtime = false;
    };

    # Ensure systemd user sessions also get unlimited memlock
    # (PAM limits alone are insufficient with systemd-managed sessions)
    systemd.user.extraConfig = "DefaultLimitMEMLOCK=infinity";

    # Kernel modules for MIDI device support
    boot.kernelModules = [
      "snd-seq"
      "snd-rawmidi"
    ];
  };

  # Home-manager: Ardour + LV2 plugins
  # Note: LV2 plugins preferred over VST2 due to nixpkgs bug #310307
  flake.modules.homeManager.musicProduction =
    { pkgs, ... }:
    {
      home.packages = [
        # DAWs
        pkgs.ardour
        pkgs.reaper
        pkgs.zrythm # GTK4 DAW with built-in plugins

        # Trackers -- breakcore/jungle workflow
        pkgs.milkytracker # FastTracker 2 clone (.xm/.mod)
        pkgs.schismtracker # Impulse Tracker clone (.it)
        pkgs.sunvox # Modular tracker/synth

        # Modular synthesis
        pkgs.vcv-rack # Virtual Eurorack
        pkgs.cardinal # Self-contained VCV Rack as plugin (LV2/VST/CLAP)

        # Audio programming languages
        pkgs.csound # Orchestra/score language
        pkgs.faust # Functional DSP language (compiles to C++, LLVM, WASM, etc.)

        # MIDI routing
        pkgs.alsa-utils # aconnect, amidi, aplaymidi
        pkgs.qpwgraph # PipeWire/JACK/ALSA patchbay GUI

        # Synths
        pkgs.vital # Wavetable synth
        pkgs.surge-xt # Open-source hybrid synth

        # LV2 plugins -- essentials for mixing/mastering/sound design
        pkgs.lsp-plugins # EQ, compressor, gate, limiter, analyser
        pkgs.calf # Synths, effects, analysers
        pkgs.x42-plugins # Meters, EQ, tuner
        pkgs.zam-plugins # Compressors, EQ, delay
        pkgs.dragonfly-reverb # Algorithmic reverb suite
        pkgs.tap-plugins # Tom's Audio Processing (LADSPA)
        pkgs.carla # Plugin host and patchbay (useful for routing)
      ];
    };
}
