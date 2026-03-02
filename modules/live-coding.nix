# Live Coding - Algorave and live coding tools
# Relies on audio.nix for PipeWire/JACK base
# After first install, run SuperCollider IDE and execute: Quarks.install("SuperDirt")
_: {
  flake.modules.homeManager.liveCoding =
    { pkgs, ... }:
    {
      home.packages = [
        # Core: SuperCollider with community plugins (audio engine for TidalCycles/FoxDot)
        pkgs.supercollider-with-sc3-plugins

        # TidalCycles: Haskell live coding pattern language
        pkgs.haskellPackages.tidal

        # pkgs.sonic-pi # broken: boost 1.89 in nixpkgs

        # ChucK: strongly-timed audio programming language
        pkgs.chuck
        # pkgs.miniaudicle # broken: Qt 6.10 qmake regression in nixpkgs

        # Pure Data: visual dataflow programming for audio/video
        pkgs.puredata

        # FoxDot: Python live coding with SuperCollider
        pkgs.foxdot

        # ORCA: esoteric 2D grid-based sequencer
        pkgs.orca-c
      ];
    };
}
