# GTK Theming Module Group
# Provides visual theming and behavioral settings for GTK applications
{
  signalLib,
  signalPalette,
  semantic,
  nix-colorizer,
}:
{
  lib,
  ...
}:
let
  # Helper to apply module arguments using importApply pattern
  applyModule =
    mod:
    lib.modules.importApply mod {
      inherit
        signalLib
        nix-colorizer
        signalPalette
        semantic
        ;
    };
in
{
  imports = [
    (applyModule ./theme.nix) # Visual theming (CSS, colors, Adwaita palette)
    (applyModule ./dconf.nix) # Behavioral settings (animations, font rendering, interface preferences)
  ];
}
