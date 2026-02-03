# Nix-ld Module - Dendritic Pattern
# Run unpatched dynamic binaries on NixOS
{ ... }:
{
  flake.modules.nixos.nixLd = { pkgs, ... }: {
    programs.nix-ld = {
      enable = true;
      libraries = [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        pkgs.openssl
        pkgs.curl
        pkgs.libz
        pkgs.libgcc
        pkgs.glibc
        pkgs.xorg.libX11
        pkgs.xorg.libXcursor
        pkgs.xorg.libXrandr
        pkgs.xorg.libXi
      ];
    };
  };
}
