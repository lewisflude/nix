# DaVinci Resolve - video editing, colour grading, Fairlight audio
# Dendritic pattern: Full implementation as flake.modules.homeManager.davinciResolve
#
# Free edition. The nixpkgs derivation is a fixed-output fetch straight from
# Blackmagic plus a buildFHSEnv wrapper, so first build downloads ~3 GB and is
# not served by cache.nixos.org (unfree, Hydra never builds it).
#
# Qt/X11 only - runs through xwayland-satellite on Niri (see niri/session.nix).
# GPU acceleration uses the NVIDIA OpenCL/CUDA ICDs from flake.modules.nixos.graphics.
_: {
  flake.modules.homeManager.davinciResolve =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [ pkgs.davinci-resolve ];
    };

  # Blackmagic device access: Speed Editor, control panels, BRAW readers.
  # The package ships its own rules under lib/udev/rules.d.
  flake.modules.nixos.davinciResolve =
    { pkgs, ... }:
    {
      services.udev.packages = [ pkgs.davinci-resolve ];
    };
}
