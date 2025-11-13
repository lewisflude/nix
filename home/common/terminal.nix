{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
in
{
  home.packages =
    [
      pkgs.clipse
      pkgs.comma
      pkgs.devenv
      # Note: eza is handled via programs.eza in apps/eza.nix
      pkgs.rsync
      pkgs.trash-cli
      pkgs.fd
      pkgs.dust
      pkgs.procs
      pkgs.gping
      pkgs.tldr
      pkgs.p7zip
      pkgs.pigz
      pkgs.git-extras
    ]
    ++
      platformLib.platformPackages
        [
          pkgs.networkmanager
          pkgs.lsof
          pkgs.wtype
        ]
        [ ]; # Linux packages, Darwin packages
  programs.ghostty = {
    enable = true;
    package = if platformLib.isLinux then pkgs.ghostty else null;
    enableZshIntegration = true;
    settings = {
      font-family = "Iosevka Nerd Font";
      font-feature = "+calt,+liga,+dlig";
      font-size = 12;
      font-synthetic-style = true;
      scrollback-limit = 100000;

      keybind = [ "shift+enter=text:\n" ];
    };
  };
}
