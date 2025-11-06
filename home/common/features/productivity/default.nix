{
  lib,
  host,
  pkgs,
  ...
}:
let
  cfg = host.features.productivity;
in
{
  imports = [
    ./resume.nix
  ];

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      lib.optionals cfg.office [
        libreoffice-fresh
      ];
    # Note: obsidian is handled via programs.obsidian in apps/obsidian.nix
    # Note: thunderbird is handled via programs.thunderbird in apps/thunderbird.nix
  };
}
