# DaVinci Resolve video editor
_: {
  flake.modules.homeManager.davinciResolve =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.isLinux {
      home.packages = [
        pkgs.davinci-resolve
      ];
    };
}
