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
  imports = [
    ../../apps/obsidian.nix
  ];

  config = lib.mkIf cfg.enable {
    home.packages = lib.flatten [
      (lib.optional cfg.office pkgs.libreoffice-fresh)
      (lib.optional cfg.calendar pkgs.gnome-calendar)
      (lib.optional cfg.email pkgs.thunderbird)
      (lib.optionals cfg.resume [
        pkgs.typst
        pkgs.tectonic # Modern LaTeX replacement
      ])
    ];

    programs.obsidian.enable = cfg.notes;
  };
}
