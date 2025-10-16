{
  lib,
  host,
  pkgs,
  ...
}: let
  cfg = host.features.productivity;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      lib.optionals cfg.office [
        libreoffice-fresh
      ]
      ++ lib.optionals cfg.notes [
        obsidian
      ]
      ++ lib.optionals cfg.email [
        thunderbird
      ];
  };
}
