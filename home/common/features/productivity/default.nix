{
  lib,
  osConfig ? {},
  pkgs,
  ...
}:
let
  # Use osConfig (home-manager's access to NixOS config)
  cfg = osConfig.host.features.productivity or {};
  # Check if productivity feature is enabled
  enabled = cfg.enable or false;
in
{
  imports = [
    ../../apps/obsidian.nix
  ];

  config = lib.mkIf enabled {
    home.packages = lib.flatten [
      (lib.optional (cfg.office or false) pkgs.libreoffice-fresh)
      (lib.optional (cfg.calendar or false) pkgs.gnome-calendar)
      (lib.optionals (cfg.resume or false) [
        pkgs.typst
        pkgs.tectonic # Modern LaTeX replacement
      ])
    ];

    programs.thunderbird = {
      enable = cfg.email or false;
      profiles = {
        default = {
          isDefault = true;
        };
      };
    };

    programs.obsidian.enable = cfg.notes or false;
  };
}
