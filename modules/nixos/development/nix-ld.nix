{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.development.nix-ld;
in
{
  options.host.development.nix-ld = {
    enable = lib.mkEnableOption "nix-ld for running unpatched dynamic binaries" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable nix-ld for running unpatched dynamic binaries on NixOS
    # This is particularly useful for:
    # - Running binaries from npm/cargo/etc
    # - Using development tools that expect a traditional Linux FHS
    # - Building applications like Zed that use dynamic linking during build
    programs.nix-ld = {
      enable = true;

      # Provide common libraries that dynamically linked binaries might need
      libraries = [
        # C/C++ standard libraries
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib

        # Common system libraries
        pkgs.openssl
        pkgs.curl
        pkgs.libz

        # Development libraries
        pkgs.libgcc
        pkgs.glibc

        # Additional libraries for build tools
        pkgs.xorg.libX11
        pkgs.xorg.libXcursor
        pkgs.xorg.libXrandr
        pkgs.xorg.libXi
      ];
    };
  };
}
