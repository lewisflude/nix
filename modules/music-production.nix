# Music Production - Ardour DAW with pro audio optimizations
# Relies on audio.nix for PipeWire/JACK base; adds DAW, plugins, and musnix tuning
# References:
# - https://wiki.nixos.org/wiki/Audio_production
# - https://github.com/musnix/musnix
# - https://wiki.nixos.org/wiki/JACK
{ ... }:
{
  # NixOS: realtime audio optimizations via musnix
  flake.modules.nixos.musicProduction =
    { ... }:
    {
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
        # DAW
        pkgs.ardour

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
