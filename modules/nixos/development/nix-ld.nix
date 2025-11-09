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
      libraries = with pkgs; [
        # C/C++ standard libraries
        stdenv.cc.cc.lib
        zlib

        # Common system libraries
        openssl
        curl
        libz

        # Development libraries
        libgcc
        glibc

        # Additional libraries for build tools
        xorg.libX11
        xorg.libXcursor
        xorg.libXrandr
        xorg.libXi
      ];
    };
  };
}
