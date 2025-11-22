{
  lib,
  systemConfig,
  pkgs,
  ...
}:
let
  cfg = systemConfig.host.features.productivity;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals cfg.office [
      pkgs.libreoffice-fresh
    ];
    # Note: obsidian is handled via programs.obsidian in apps/obsidian.nix
    # Note: thunderbird is handled via programs.thunderbird in apps/thunderbird.nix
  };
}
