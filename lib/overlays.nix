# Package overlays for consistent package management across the configuration
# This makes our custom package sets available as pkgs.myPackages.*

{ configVars }:

[
  # Custom package sets overlay
  (final: prev: {
    myPackages = import ./packages.nix {
      pkgs = final;
      inherit configVars;
      lib = final.lib;
    };
  })
]