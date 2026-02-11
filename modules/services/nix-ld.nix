# Nix-ld Module - Dendritic Pattern
# Run unpatched dynamic binaries on NixOS
_:
{
  flake.modules.nixos.nixLd =
    { pkgs, ... }:
    {
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
          pkgs.libx11
          pkgs.libxcursor
          pkgs.libxrandr
          pkgs.libxi
        ];
      };
    };
}
